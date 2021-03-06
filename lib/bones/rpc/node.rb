# encoding: utf-8
require 'bones/rpc/address'
require 'bones/rpc/connection'
require 'bones/rpc/failover'
require 'bones/rpc/instrumentable'
require 'bones/rpc/node/registry'

module Bones
  module RPC

    # Represents a client to a node in a server cluster.
    #
    # @since 0.0.1
    class Node
      include Instrumentable

      # @!attribute address
      #   @return [ Address ] The address.
      # @!attribute down_at
      #   @return [ Time ] The time the node was marked as down.
      # @!attribute latency
      #   @return [ Integer ] The latency in milliseconds.
      # @!attribute options
      #   @return [ Hash ] The node options.
      # @!attribute refreshed_at
      #   @return [ Time ] The last time the node did a refresh.
      attr_reader :cluster, :address, :down_at, :latency, :refreshed_at

      # Is this node equal to another?
      #
      # @example Is the node equal to another.
      #   node == other
      #
      # @param [ Node ] other The other node.
      #
      # @return [ true, false ] If the addresses are equal.
      #
      # @since 0.0.1
      def ==(other)
        return false unless other.is_a?(Node)
        address.resolved == other.address.resolved
      end
      alias :eql? :==

      def adapter
        @adapter ||= Adapter.get(options[:adapter] || :json)
      end

      def attach(channel, id, future)
        @registry.set(channel, id, future)
      end

      def cleanup_socket(socket)
        @registry.flush
      end

      # Connect the node on the underlying connection.
      #
      # @example Connect the node.
      #   node.connect
      #
      # @raise [ Errors::ConnectionFailure ] If connection failed.
      #
      # @return [ true ] If the connection suceeded.
      #
      # @since 0.0.1
      def connect
        start = Time.now
        connection { |conn| conn.connect }
        @latency = Time.now - start
        @down_at = nil
        true
      end

      # Is the node currently connected?
      #
      # @example Is the node connected?
      #   node.connected?
      #
      # @return [ true, false ] If the node is connected or not.
      #
      # @since 0.0.1
      def connected?
        connection { |conn| conn.alive? }
      end

      def connection
        if block_given?
          yield @connection
        else
          @connection
        end
      end

      def detach(channel, id)
        @registry.get(channel, id)
      end

      # Force the node to disconnect from the server.
      #
      # @example Disconnect the node.
      #   node.disconnect
      #
      # @return [ true ] If the disconnection succeeded.
      #
      # @since 0.0.1
      def disconnect
        connection { |conn| conn.disconnect }
        true
      end

      # Is the node down?
      #
      # @example Is the node down?
      #   node.down?
      #
      # @return [ Time, nil ] The time the node went down, or nil if up.
      #
      # @since 0.0.1
      def down?
        !!@down_at
      end

      # Mark the node as down.
      #
      # @example Mark the node as down.
      #   node.down
      #
      # @return [ nil ] Nothing.
      #
      # @since 0.0.1
      def down
        @down_at = Time.new
        @latency = nil
        disconnect if connected?
      end

      # Yields the block if a connection can be established, retrying when a
      # connection error is raised.
      #
      # @example Ensure we are connection.
      #   node.ensure_connected do
      #     #...
      #   end
      #
      # @raises [ ConnectionFailure ] When a connection cannot be established.
      #
      # @return [ nil ] nil.
      #
      # @since 0.0.1
      def ensure_connected(&block)
        begin
          connect unless connected?
          yield(current_actor)
        rescue Exception => e
          Failover.get(e).execute(e, current_actor, &block)
        end
      end

      def handle_message(message)
        logging(message) do
          if future = message.get(current_actor)
            message.signal(future)
          end
        end
      end

      def initialize(cluster, address)
        @cluster = cluster
        @address = address
        @connection = cluster.session.backend.connection_class.new(current_actor)
        @down_at = nil
        @refreshed_at = nil
        @latency = nil
        @instrumenter = @cluster.options[:instrumenter] || Instrumentable::Log
        @registry = Node::Registry.new
        @request_id = 0
        @synack_id = 0
        @address.resolve(current_actor)
      end

      # Get the node as a nice formatted string.
      #
      # @example Inspect the node.
      #   node.inspect
      #
      # @return [ String ] The string inspection.
      #
      # @since 0.0.1
      def inspect
        "<#{self.class.name} resolved_address=#{address.resolved.inspect}>"
      end

      # Does the node need to be refreshed?
      #
      # @example Does the node require refreshing?
      #   node.needs_refresh?(time)
      #
      # @param [ Time ] time The next referesh time.
      #
      # @return [ true, false] Whether the node needs to be refreshed.
      #
      # @since 0.0.1
      def needs_refresh?(time)
        !refreshed_at || refreshed_at < time
      end

      def notify(method, params)
        without_future(Protocol::Notify.new(method, params))
      end

      def options
        cluster.options
      end

      # Refresh information about the node, such as it's status in the replica
      # set and it's known peers.
      #
      # @example Refresh the node.
      #   node.refresh
      #
      # @raise [ ConnectionFailure ] If the node cannot be reached.
      #
      # @raise [ ReplicaSetReconfigured ] If the node is no longer a primary node and
      #   refresh was called within an +#ensure_primary+ block.
      #
      # @return [ nil ] nil.
      #
      # @since 0.0.1
      def refresh
        if address.resolve(current_actor)
          begin
            @refreshed_at = Time.now
            if synchronize.value(refresh_timeout)
              cluster.handle_refresh(current_actor)
            else
              down
            end
          rescue Timeout::Error
            down
          end
        end
      end

      # Get the timeout, in seconds, for this node.
      #
      # @example Get the timeout in seconds.
      #   node.refresh_timeout
      #
      # @return [ Integer ] The configured timeout or the default of 5.
      #
      # @since 0.0.1
      def refresh_timeout
        @refresh_timeout ||= (options[:timeout] || 5)
      end

      def registry_empty?
        @registry.empty?
      end

      def request(method, params)
        with_future(Protocol::Request.new(next_request_id, method, params))
      end

      def synchronize
        with_future(Protocol::Synchronize.new(next_synack_id, adapter))
      end

      private

      # Yield the block with logging.
      #
      # @api private
      #
      # @example Yield with logging.
      #   logging(operations) do
      #     node.command(ismaster: 1)
      #   end
      #
      # @param [ Array<Message> ] operations The operations.
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 0.0.1
      def logging(message)
        instrument(TOPIC, prefix: "  BONES-RPC: #{address.resolved}", ops: [message]) do
          yield if block_given?
        end
      end

      def next_request_id
        @request_id += 1
        if @request_id >= 1 << 31
          @request_id = 0
        end
        @request_id
      end

      def next_synack_id
        @synack_id += 1
        if @synack_id >= (1 << 32) - 1
          @synack_id = 0
        end
        @synack_id
      end

      def process(message, future = nil)
        logging(message) do
          ensure_connected do
            connection { |conn| conn.write([[message, future]]) }
          end
        end
        return future
      rescue Exception => e
        abort(e)
      end

      def with_future(message)
        process(message, cluster.session.backend.future_class.new)
      end

      def without_future(message)
        process(message, nil)
      end
    end
  end
end
