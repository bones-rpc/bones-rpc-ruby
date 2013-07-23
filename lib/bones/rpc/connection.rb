# encoding: utf-8
require 'bones/rpc/connection/reader'
require 'bones/rpc/connection/socket'
require 'bones/rpc/connection/writer'

module Bones
  module RPC

    # This class contains behaviour of Bones::RPC socket connections.
    #
    # @since 2.0.0
    class Connection

      # The default connection timeout, in seconds.
      #
      # @since 2.0.0
      TIMEOUT = 5

      attr_reader :node, :socket

      # Is the connection alive?
      #
      # @example Is the connection alive?
      #   connection.alive?
      #
      # @return [ true, false ] If the connection is alive.
      #
      # @since 1.0.0
      def alive?
        connected? ? @socket.alive? : false
      end

      def cleanup_socket(socket)
        if @writer
          @writer.async.terminate if @writer.alive?
          @writer = nil
        end
        @node.cleanup_socket(socket)
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
        if @writer
          @writer.terminate
          @writer = nil
        end
        @socket = if !!options[:ssl]
          Socket::SSL.connect(host, port, timeout)
        else
          Socket::TCP.connect(host, port, timeout)
        end
        writer
        return true
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
        !!@socket
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
        @socket.close
      rescue
      ensure
        @socket = nil
      end

      def host
        node.address.ip
      end

      def initialize(node)
        @node = node
        @socket = nil
      end

      def inspect
        "<#{self.class} \"#{node.address.resolved}\">"
      end

      def options
        node.options
      end

      def port
        node.address.port
      end

      def timeout
        options[:timeout] || Connection::TIMEOUT
      end

      def write(operations)
        with_connection do |socket|
          writer.write(operations)
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
        connect if @socket.nil? || !@socket.alive?
        yield @socket
      end

      def writer
        @writer ||= Writer.new(self, @socket, node.adapter)
      end
    end
  end
end
