# encoding: utf-8
module Bones
  module RPC
    module Synchronous
      class Connection
        class Writer
          attr_reader :reader

          def initialize(connection, socket, adapter)
            @connection = connection
            @socket = socket
            @adapter = adapter
            @resolved = @connection.node.address.resolved
            @alive = true
            @buffer = ""
            @reader = Reader.new(@connection, @socket, @adapter, self)
          end

          def alive?
            !!@alive
          end

          def async
            self
          end

          def write(operations)
            proxy = NodeProxy.new(@connection.node)
            operations.each do |message, future|
              message.serialize(@buffer, @adapter)
              message.attach(proxy, future) if future
            end
            @socket.write(@buffer)
            @buffer = ""
            return proxy
          rescue EOFError, Errors::ConnectionFailure => e
            Loggable.warn("  BONES-RPC:", "#{@resolved} Writer terminating: #{e.message}", "n/a")
            terminate
            raise e
          end

          def terminate
            return if not alive?
            @alive = false
            @reader.terminate
            @connection.cleanup_socket(@socket)
          end

          class NodeProxy < ::BasicObject
            def attach(channel, id, future)
              @registry.set(channel, id, future)
            end

            def detach(channel, id)
              @registry.get(channel, id)
            end

            def handle_message(message)
              logging(message) do
                if future = message.get(self)
                  message.signal(future)
                end
              end
            end

            def initialize(node)
              @node = node
              @registry = Node::Registry.new
            end

            def registry_empty?
              @registry.empty?
            end

            protected

            def method_missing(name, *args, &block)
              @node.__send__(name, *args, &block)
            end
          end

        end
      end
    end
  end
end
