# encoding: utf-8
require 'openssl'

module Bones
  module RPC
    class Connection
      module Socket

        # This is a wrapper around a tcp socket.
        class SSL < ::Celluloid::IO::SSLSocket
          include Connectable

          # Initialize the new TCPSocket with SSL.
          #
          # @example Initialize the socket.
          #   SSL.new("127.0.0.1", 27017)
          #
          # @param [ String ] host The host.
          # @param [ Integer ] port The port.
          #
          # @since 1.2.0
          def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
            @host, @port = remote_host, remote_port
            handle_socket_errors do
              socket = TCPSocket.new(remote_host, remote_port, local_host, local_port)
              super(socket)
              to_io.sync_close = true
              connect
            end
          end
        end
      end
    end
  end
end
