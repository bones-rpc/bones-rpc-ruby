# encoding: utf-8
module Bones
  module RPC
    class Connection
      module Socket

        # This is a wrapper around a ssl socket.
        class TCP < ::Celluloid::IO::TCPSocket
          include Connectable

          # Initialize the new TCPSocket.
          #
          # @example Initialize the socket.
          #   TCP.new("127.0.0.1", 27017)
          #
          # @param [ String ] remote_host The host.
          # @param [ Integer ] remote_port The port.
          #
          # @since 1.2.0
          def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
            @host, @port = remote_host, remote_port
            handle_socket_errors { super }
          end
        end
      end
    end
  end
end
