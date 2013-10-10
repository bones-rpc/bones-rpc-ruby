# encoding: utf-8
module Bones
  module RPC
    module Synchronous
      class Connection
        class Reader
          def initialize(connection, socket, adapter, writer)
            @connection = connection
            @socket = socket
            @adapter = adapter
            @writer = writer
            @alive = true
            @buffer = ""
          end

          def alive?
            !!@alive
          end

          def parse(data, proxy)
            @buffer << data
            if @buffer.empty?
              read(proxy)
            else
              parser = Bones::RPC::Parser.new(@buffer, @adapter)
              begin
                loop { send parser.read, proxy }
              rescue EOFError
                @buffer.replace(parser.buffer.to_str)
              end
              return if @buffer.empty?
              read(proxy)
            end
          end

          def read(proxy)
            parse @socket.readpartial(4096), proxy
          rescue EOFError, Errors::ConnectionFailure => e
            Loggable.warn("  BONES-RPC:", "#{@connection.node.address.resolved} Reader terminating: #{e.message}", "n/a")
            terminate
            raise e
          end

          def send(message, proxy)
            proxy.handle_message(message)
          end

          def terminate
            return if not alive?
            @alive = false
            @buffer.clear
            @writer.terminate
          end

        end
      end
    end
  end
end
