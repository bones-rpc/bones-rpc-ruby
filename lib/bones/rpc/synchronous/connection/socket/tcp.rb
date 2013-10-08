# encoding: utf-8
module Bones
  module RPC
    module Synchronous
      class Connection
        module Socket

          # This is a wrapper around a tcp socket.
          class TCP < ::TCPSocket
            include ::Bones::RPC::Connection::Socket::Connectable

            # Initialize the new TCPSocket.
            #
            # @example Initialize the socket.
            #   TCP.new("127.0.0.1", 27017)
            #
            # @param [ String ] remote_host The host.
            # @param [ Integer ] remote_port The port.
            #
            # @since 0.0.1
            def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
              @host, @port = remote_host.to_s, remote_port
              handle_socket_errors { super(@host, port, local_host, local_port) }
            end
          end
        end
      end
    end
  end
end
