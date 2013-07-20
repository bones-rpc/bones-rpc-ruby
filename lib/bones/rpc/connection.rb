# encoding: utf-8
require 'bones/rpc/connection/manager'
require 'bones/rpc/connection/pool'
require 'bones/rpc/connection/queue'
require 'bones/rpc/connection/reader'
require 'bones/rpc/connection/reaper'
require 'bones/rpc/connection/socket'
require 'bones/rpc/connection/writer'

module Bones
  module RPC

    # This class contains behaviour of database socket connections.
    #
    # @since 2.0.0
    class Connection

      # The default connection timeout, in seconds.
      #
      # @since 2.0.0
      TIMEOUT = 5

      # @!attribute host
      #   @return [ String ] The ip address of the host.
      # @!attribute options
      #   @return [ Hash ] The connection options.
      # @!attribute port
      #   @return [ String ] The port the connection connects on.
      # @!attribute timeout
      #   @return [ Integer ] The timeout in seconds.
      # @!attribute last_use
      #   @return [ Time ] The time the connection was last checked out.
      attr_reader :pool, :last_use

      def adapter
        @adapter ||= Adapter.get(options[:adapter] || :msgpack)
      end

      # Is the connection alive?
      #
      # @example Is the connection alive?
      #   connection.alive?
      #
      # @return [ true, false ] If the connection is alive.
      #
      # @since 1.0.0
      def alive?
        connected? ? @sock.alive? : false
      end

      def cleanup_socket(socket)
        disconnect
        @writer = nil
        pool.node.cleanup_socket(socket)
      end

      # Connect to the server defined by @host, @port without timeout @timeout.
      #
      # @example Open the connection
      #   connection.connect
      #
      # @return [ TCPSocket ] The socket.
      #
      # @since 1.0.0
      def connect
        (@writer.async.terminate rescue nil) if @writer
        @sock = if !!options[:ssl]
          Socket::SSL.connect(host, port, timeout)
        else
          Socket::TCP.connect(host, port, timeout)
        end
        @writer = Writer.new(self, @sock)
        pool.node.on_connect(@sock)
        @sock
      end

      # Is the connection connected?
      #
      # @example Is the connection connected?
      #   connection.connected?
      #
      # @return [ true, false ] If the connection is connected.
      #
      # @since 1.0.0
      def connected?
        !!@sock
      end

      # Disconnect from the server.
      #
      # @example Disconnect from the server.
      #   connection.disconnect
      #
      # @return [ nil ] nil.
      #
      # @since 1.0.0
      def disconnect
        @sock.close
      rescue
      ensure
        @sock = nil
      end

      # Initialize the connection.
      #
      # @example Initialize the connection.
      #   Connection.new("localhost", 27017, 5)
      #
      # @param [ String ] host The host to connect to.
      # @param [ Integer ] post The server port.
      # @param [ Integer ] timeout The connection timeout.
      # @param [ Hash ] options Options for the connection.
      #
      # @option options [ Boolean ] :ssl Connect using SSL
      # @since 1.0.0
      # def initialize(host, port, timeout, options = {})
      def initialize(pool)
        @pool = pool
        @sock = nil
        @last_use = nil
        @request_id = 0
      end

      # Expiring a connection means returning it to the connection pool.
      #
      # @example Expire the connection.
      #   connection.expire
      #
      # @return [ nil ] nil.
      #
      # @since 2.0.0
      def expire
        @last_use = nil
      end

      # An expired connection is not currently being used.
      #
      # @example Is the connection expired?
      #   connection.expired?
      #
      # @return [ true, false ] If the connection is expired.
      #
      # @since 2.0.0
      def expired?
        @last_use.nil?
      end

      def host
        pool.host
      end

      # A leased connection is currently checkout out from the connection pool.
      #
      # @example Lease the connection.
      #   connection.lease
      #
      # @return [ Time ] The current time of leasing.
      #
      # @since 2.0.0
      def lease
        @last_use = Time.now
      end

      def options
        pool.options
      end

      def port
        pool.port
      end

      def timeout
        pool.options[:timeout] || Connection::TIMEOUT
      end

      def write(operations)
        with_connection do |socket|
          @writer.async.write(operations)
        end
      end

      private

      # Yields a connected socket to the calling back. It will attempt to reconnect
      # the socket if it is not connected.
      #
      # @api private
      #
      # @example Write to the connection.
      #   with_connection do |socket|
      #     socket.write(buf)
      #   end
      #
      # @return The yielded block
      #
      # @since 1.3.0
      def with_connection
        connect if @sock.nil? || !@sock.alive?
        yield @sock
      end
    end
  end
end
