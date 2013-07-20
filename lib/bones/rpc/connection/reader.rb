# encoding: utf-8
module Bones
  module RPC
    class Connection
      class Reader
        include Celluloid::IO

        execute_block_on_receiver :initialize

        def initialize(connection, socket)
          @connection = connection
          @socket = socket
          @adapter = connection.adapter
          @node = @connection.pool.node
          @buffer = ""
          async.read
        end

        def parse(data)
          @buffer << data
          if @buffer.empty?
            async.read
          else
            parser = Bones::RPC::Parser.new(@buffer, @adapter)
            begin
              loop { async.send parser.read }
            rescue EOFError
              @buffer.replace(parser.buffer.to_str)
            end
            async.read
          end
        end

        def read
          loop do
            async.parse @socket.readpartial(4096)
          end
        rescue EOFError, Errors::ConnectionFailure => e
          Loggable.warn("  BONES-RPC:", "Reader terminating: #{e.message}", "n/a")
          terminate
        end

        def send(message)
          @node.on_message(message, @socket)
        end

      end
    end
  end
end
