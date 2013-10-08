# encoding: utf-8
module Bones
  module RPC
    class Node
      class Registry

        def initialize
          @registry = {}
        end

        def empty?
          @registry.empty? || @registry.all? { |channel, child| child.empty? }
        end

        def flush(exception = Errors::ConnectionFailure.new("Socket closed"))
          return true if @registry.empty?
          @registry.each do |channel, futures|
            futures.each do |id, future|
              future.signal(FutureValue.new(exception)) rescue nil
            end
          end
          @registry.clear
        end

        def get(channel, id)
          (@registry[channel] ||= {}).delete(id)
        end

        def set(channel, id, future)
          (@registry[channel] ||= {})[id] = future
        end

      end
    end
  end
end
