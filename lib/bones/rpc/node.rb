# encoding: utf-8
require 'bones/rpc/address'
require 'bones/rpc/connection'
require 'bones/rpc/executable'
require 'bones/rpc/failover'
require 'bones/rpc/future'
require 'bones/rpc/instrumentable'
require 'bones/rpc/responsive'

module Bones
  module RPC

    # Represents a client to a node in a server cluster.
    #
    # @since 1.0.0
    class Node
      include Executable
      include Instrumentable
      include Responsive

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
      attr_reader :address, :down_at, :latency, :options, :refreshed_at

      # Is this node equal to another?
      #
      # @example Is the node equal to another.
      #   node == other
      #
      # @param [ Node ] other The other node.
      #
      # @return [ true, false ] If the addresses are equal.
      #
      # @since 1.0.0
      def ==(other)
        return false unless other.is_a?(Node)
        id == other.id
      end
      alias :eql? :==

      def adapter
        @adapter ||= Adapter.get(options[:adapter] || :msgpack)
      end

      def attach(socket, operation, future)
        operation.store(self, socket, future)
      end

      def cleanup_socket(socket)
        @refreshed_at = nil
        futures_flush(socket, Errors::ConnectionFailure.new("Socket closed"))
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
      # @since 2.0.0
      def connect
        start = Time.now
        connection{ |conn| conn.connect }
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
      # @since 2.0.0
      def connected?
        connection{ |conn| conn.alive? }
      end

      # Get the underlying connection for the node.
      #
      # @example Get the node's connection.
      #   node.connection
      #
      # @return [ Connection ] The connection.
      #
      # @since 2.0.0
      def connection
        pool.with_connection do |conn|
          yield(conn)
        end
      end

      # Force the node to disconnect from the server.
      #
      # @example Disconnect the node.
      #   node.disconnect
      #
      # @return [ true ] If the disconnection succeeded.
      #
      # @since 1.2.0
      def disconnect
        connection{ |conn| conn.disconnect }
        true
      end

      # Is the node down?
      #
      # @example Is the node down?
      #   node.down?
      #
      # @return [ Time, nil ] The time the node went down, or nil if up.
      #
      # @since 1.0.0
      def down?
        @down_at
      end

      # Mark the node as down.
      #
      # @example Mark the node as down.
      #   node.down!
      #
      # @return [ nil ] Nothing.
      #
      # @since 2.0.0
      def down!
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
      # @since 1.0.0
      def ensure_connected(&block)
        return yield if executing?(:connection)
        execute(:connection) do
          begin
            connect unless connected?
            yield(self)
          rescue Exception => e
            Failover.get(e).execute(e, self, &block)
          end
        end
      end

      # Get the hash identifier for the node.
      #
      # @example Get the hash identifier.
      #   node.hash
      #
      # @return [ Integer ] The hash identifier.
      #
      # @since 1.0.0
      def hash
        id.hash
      end

      def id
        "#{address.resolved}"
      end

      # Create the new node.
      #
      # @example Create the new node.
      #   Node.new("127.0.0.1:27017")
      #
      # @param [ String ] address The location of the server node.
      # @param [ Hash ] options Additional options for the node (ssl)
      #
      # @since 1.0.0
      def initialize(address, options = {})
        @address = address
        @options = options
        @down_at = nil
        @refreshed_at = nil
        @latency = nil
        @instrumenter = options[:instrumenter] || Instrumentable::Log
        @address.resolve(self)
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
      # @since 1.0.0
      def needs_refresh?(time)
        !refreshed_at || refreshed_at < time
      end

      def notify(method, params)
        oneway(Protocol::Notify.new(method, params))
      end

      def on_connect(socket)
      end

      def on_message(message, socket)
        logging([message]) do
          if future = message.get(self, socket)
            message.signal(future)
          end
        end
      end

      # Execute a pipeline of commands, for example a safe mode persist.
      #
      # @example Execute a pipeline.
      #   node.pipeline do
      #     #...
      #   end
      #
      # @return [ nil ] nil.
      #
      # @since 1.0.0
      # @todo: Remove with piggbacked gle.
      def pipeline
        execute(:pipeline) do
          yield(self)
        end
        flush unless executing?(:pipeline)
      end

      # Processes the provided operation on this node, and will execute the
      # callback when the operation is sent to the database.
      #
      # @example Process a read operation.
      #   node.process(query) do |reply|
      #     return reply.documents
      #   end
      #
      # @param [ Message ] operation The database operation.
      # @param [ Proc ] callback The callback to run on operation completion.
      #
      # @return [ Object ] The result of the callback.
      #
      # @since 1.0.0
      def process(operation, future=nil)
        if executing?(:pipeline)
          queue.push([operation, future])
        else
          flush([[operation, future]])
        end
        return future
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
      # @since 1.0.0
      def refresh
        if address.resolve(self)
          begin
            @refreshed_at = Time.now
            if synchronize.value(timeout)
              nil
            else
              down!
            end
          rescue Timeout::Error
            down!
          end
        end
      end

      def request(method, params)
        twoway(Protocol::Request.new(pool.message_id, method, params))
      end

      def synchronize
        twoway(Protocol::Synchronize.new(pool.synchronize_id, adapter))
      end

      # Get the timeout, in seconds, for this node.
      #
      # @example Get the timeout in seconds.
      #   node.timeout
      #
      # @return [ Integer ] The configured timeout or the default of 5.
      #
      # @since 1.0.0
      def timeout
        @timeout ||= (options[:timeout] || 5)
      end

      # Get the node as a nice formatted string.
      #
      # @example Inspect the node.
      #   node.inspect
      #
      # @return [ String ] The string inspection.
      #
      # @since 1.0.0
      def inspect
        "<#{self.class.name} resolved_address=#{address.resolved.inspect}>"
      end

      private

      # Flush the node operations to the database.
      #
      # @api private
      #
      # @example Flush the operations.
      #   node.flush([ command ])
      #
      # @param [ Array<Message> ] ops The operations to flush.
      #
      # @return [ Object ] The result of the operations.
      #
      # @since 2.0.0
      def flush(ops = queue)
        operations, futures = ops.transpose
        logging(operations) do
          ensure_connected do
            connection do |conn|
              conn.write(ops.dup)
            end
          end
        end
      ensure
        ops.clear
      end

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
      # @since 2.0.0
      def logging(operations)
        instrument(TOPIC, prefix: "  BONES-RPC: #{address.resolved}", ops: operations) do
          yield if block_given?
        end
      end

      def oneway(operation)
        process(operation)
      end

      # Get the connection pool for the node.
      #
      # @api private
      #
      # @example Get the connection pool.
      #   node.pool
      #
      # @return [ Connection::Pool ] The connection pool.
      #
      # @since 2.0.0
      def pool
        @pool ||= Connection::Manager.pool(self)
      end

      def twoway(operation)
        process(operation, Bones::RPC::Future.new)
      end

      # Get the queue of operations.
      #
      # @api private
      #
      # @example Get the operation queue.
      #   node.queue
      #
      # @return [ Array<Message> ] The queue of operations.
      #
      # @since 2.0.0
      def queue
        stack(:pipelined_operations)
      end
    end
  end
end
