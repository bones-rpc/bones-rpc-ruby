# encoding: utf-8
module Bones
  module RPC
    class Parser
      def initialize(reader)
        @node = node
        @waiting = {}
      end

      def process(message)
        puts @waiting.inspect
        puts @node.adapter.adapter_name
        puts message.inspect
        @waiting.each do |msg_id, future|
          future.signal(Response.new({msg_id => message}))
        end
        @waiting.clear
        @node.cluster.on_message(message)
      rescue => e
        Loggable.warn("  BONES-RPC:", "Parser Error: #{e.message}", "n/a")
      end

      def wait_for(future, message_id)
        @waiting[message_id] = future
      end

      class Response
        attr_reader :value
        def initialize(value)
          @value = value
        end
      end
    end
  end
end
