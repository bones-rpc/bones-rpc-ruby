# encoding: utf-8
require 'openssl'

module Bones
  module RPC
    module Synchronous
      class Connection
        module Socket

          # This is a wrapper around a tcp socket.
          class SSL < ::OpenSSL::SSL::SSLSocket
            include ::Bones::RPC::Connection::Socket::Connectable

            attr_reader :socket

            # Initialize the new TCPSocket with SSL.
            #
            # @example Initialize the socket.
            #   SSL.new("127.0.0.1", 27017)
            #
            # @param [ String ] host The host.
            # @param [ Integer ] port The port.
            #
            # @since 0.0.1
            def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
              @host, @port = remote_host.to_s, remote_port
              handle_socket_errors do
                @socket = TCPSocket.new(@host, remote_port, local_host, local_port)
                super(socket)
                self.sync_close = true
                connect
              end
            end

            # Set the encoding of the underlying socket.
            #
            # @param [ String ] string The encoding.
            #
            # @since 0.0.1
            def set_encoding(string)
              socket.set_encoding(string)
            end

            # Set a socket option on the underlying socket.
            #
            # @param [ Array<Object> ] args The option arguments.
            #
            # @since 0.0.1
            def setsockopt(*args)
              socket.setsockopt(*args)
            end
          end
        end
      end
    end
  end
end
