# encoding: utf-8
module Bones
  module RPC
    class Connection
      module Socket
        module Connectable

          attr_reader :host, :port

          # Is the socket connection alive?
          #
          # @example Is the socket alive?
          #   socket.alive?
          #
          # @return [ true, false ] If the socket is alive.
          #
          # @since 0.0.1
          def alive?
            io = to_io
            if Kernel::select([ io ], nil, [ io ], 0)
              !eof? rescue false
            else
              true
            end
          rescue IOError
            false
          end

          # Bring in the class methods when included.
          #
          # @example Extend the class methods.
          #   Connectable.included(class)
          #
          # @param [ Class ] klass The class including the module.
          #
          # @since 0.0.1
          def self.included(klass)
            klass.send(:extend, ClassMethods)
          end

          # Read from the TCP socket.
          #
          # @param [ Integer ] size The length to read.
          # @param [ String, NilClass ] buf The string which will receive the data.
          #
          # @return [ Object ] The data.
          #
          # @since 0.0.1
          def read(size = nil, buf = nil)
            check_if_alive!
            handle_socket_errors { super }
          end

          # Read from the TCP socket.
          #
          # @param [ Integer ] size The maximum length to read.
          # @param [ String, NilClass ] buf The string which will receive the data.
          #
          # @return [ Object ] The data.
          #
          # @since 0.0.1
          def readpartial(maxlen, buf = nil)
            check_if_alive!
            handle_socket_errors { super }
          end

          # Set the encoding of the underlying socket.
          #
          # @param [ String ] string The encoding.
          #
          # @since 0.0.1
          def set_encoding(string)
            if to_io != self
              to_io.set_encoding(string)
            else
              super
            end
          end

          # Write to the socket.
          #
          # @example Write to the socket.
          #   socket.write(data)
          #
          # @param [ Object ] args The data to write.
          #
          # @return [ Integer ] The number of bytes written.
          #
          # @since 0.0.1
          def write(*args)
            check_if_alive!
            handle_socket_errors { super }
          end

          private

          # Before performing a read or write operating, ping the server to check
          # if it is alive.
          #
          # @api private
          #
          # @example Check if the connection is alive.
          #   connectable.check_if_alive!
          #
          # @raise [ ConnectionFailure ] If the connectable is not alive.
          #
          # @since 0.0.1
          def check_if_alive!
            unless alive?
              raise Errors::ConnectionFailure, "Socket connection was closed by remote host"
            end
          end

          # Generate the message for the connection failure based of the system
          # call error, with some added information.
          #
          # @api private
          #
          # @example Generate the error message.
          #   connectable.generate_message(error)
          #
          # @param [ SystemCallError ] error The error.
          #
          # @return [ String ] The error message.
          #
          # @since 0.0.1
          def generate_message(error)
            "#{host}:#{port}: #{error.class.name} (#{error.errno}): #{error.message}"
          end

          # Handle the potential socket errors that can occur.
          #
          # @api private
          #
          # @example Handle the socket errors while executing the block.
          #   handle_socket_errors do
          #     socket.read(128)
          #   end
          #
          # @raise [ Bones::RPC::Errors::ConnectionFailure ] If a system call error or
          #   IOError occured which can be retried.
          # @raise [ Bones::RPC::Errors::Unrecoverable ] If a system call error occured
          #   which cannot be retried and should be re-raised.
          #
          # @return [ Object ] The result of the yield.
          #
          # @since 0.0.1
          def handle_socket_errors
            yield
          rescue Errno::ECONNREFUSED => e
            raise Errors::ConnectionFailure, generate_message(e)
          rescue Errno::EHOSTUNREACH => e
            raise Errors::ConnectionFailure, generate_message(e)
          rescue Errno::EPIPE => e
            raise Errors::ConnectionFailure, generate_message(e)
          rescue Errno::ECONNRESET => e
            raise Errors::ConnectionFailure, generate_message(e)
          rescue Errno::ETIMEDOUT => e
            raise Errors::ConnectionFailure, generate_message(e)
          rescue IOError
            raise Errors::ConnectionFailure, "Connection timed out to Bones RPC on #{host}:#{port}"
          rescue OpenSSL::SSL::SSLError => e
            raise Errors::ConnectionFailure, "SSL Error '#{e.to_s}' for connection to Bones RPC on #{host}:#{port}"
          end

          module ClassMethods

            # Connect to the tcp server.
            #
            # @example Connect to the server.
            #   TCPSocket.connect("127.0.0.1", 27017, 30)
            #
            # @param [ String ] host The host to connect to.
            # @param [ Integer ] post The server port.
            # @param [ Integer ] timeout The connection timeout.
            #
            # @return [ TCPSocket ] The socket.
            #
            # @since 0.0.1
            def connect(host, port, timeout)
              begin
                Timeout::timeout(timeout) do
                  sock = new(host, port)
                  sock.set_encoding('binary')
                  timeout_val = [ timeout, 0 ].pack("l_2")
                  sock.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)
                  sock.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_RCVTIMEO, timeout_val)
                  sock.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_SNDTIMEO, timeout_val)
                  sock
                end
              rescue Timeout::Error
                raise Errors::ConnectionFailure, "Timed out connection to Bones RPC on #{host}:#{port}"
              end
            end
          end
        end
      end
    end
  end
end
