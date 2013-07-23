# encoding: utf-8
module Bones
  module RPC
    class Connection
      class Writer
        include Celluloid::IO

        execute_block_on_receiver :initialize
        finalizer :shutdown
        trap_exit :reader_died

        def initialize(connection, socket, adapter)
          @connection = connection
          @socket = socket
          @adapter = adapter
          @resolved = @connection.node.address.resolved
          @buffer = ""
          @reader = Reader.new_link(@connection, @socket, @adapter)
        end

        def write(operations)
          operations.each do |message, future|
            message.serialize(@buffer, @adapter)
            message.attach(@connection.node, future) if future
          end
          @socket.write(@buffer)
          @buffer = ""
          return true
        rescue EOFError, Errors::ConnectionFailure => e
          Loggable.warn("  BONES-RPC:", "#{@resolved} Writer terminating: #{e.message}", "n/a")
          terminate
        end

        def shutdown
          if @reader && @reader.alive?
            @reader.unlink
            @reader.async.terminate
          end
          @connection.cleanup_socket(@socket)
        end

        def reader_died(actor, reason)
          Loggable.warn("  BONES-RPC:", "#{@resolved} Writer terminating: #{reason}", "n/a")
          @reader = nil
          terminate
        end

      end
    end
  end
end
