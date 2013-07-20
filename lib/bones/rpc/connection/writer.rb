# encoding: utf-8
module Bones
  module RPC
    class Connection
      class Writer
        include Celluloid::IO

        execute_block_on_receiver :initialize
        finalizer :shutdown
        trap_exit :reader_died

        def initialize(connection, socket)
          @connection = connection
          @socket = socket
          @node = connection.pool.node
          @adapter = connection.adapter
          @buffer = ""
          @reader = Reader.new_link(@connection, @socket)
        end

        def flush
          if not @buffer.empty?
            @socket.write(@buffer)
            @buffer = ""
          end
        rescue EOFError, Errors::ConnectionFailure => e
          Loggable.warn("  BONES-RPC:", "Writer terminating: #{e.message}", "n/a")
          terminate
        end

        def write(operations)
          @timer.cancel if @timer
          operations.each do |operation, future|
            operation.serialize(@buffer, @adapter)
            @node.attach(@socket, operation, future) if future
          end
          if @buffer.bytesize > 4096
            flush
          else
            @timer = after(0.1) { flush }
          end
        end

        def shutdown
          if @reader && @reader.alive?
            puts "READER IS ALIVE?: #{@reader.inspect}"
            @reader.unlink
            @reader.async.terminate
          end
          @connection.cleanup_socket(@socket)
        end

        def reader_died(actor, reason)
          puts "reader died: #{actor.inspect}\nreason: #{reason.inspect}"
          Loggable.warn("  BONES-RPC:", "Writer terminating", "n/a")
          @reader = nil
          terminate
        end

      end
    end
  end
end
