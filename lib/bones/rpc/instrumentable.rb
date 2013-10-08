# encoding: utf-8
require 'bones/rpc/instrumentable/log'
require 'bones/rpc/instrumentable/noop'

module Bones
  module RPC
    module Instrumentable

      # The name of the topic of operations for Bones::RPC.
      #
      # @since 0.0.1
      TOPIC = "bones-rpc.operations"

      # Topic for warning instrumentation.
      #
      # @since 0.0.1
      WARN = "bones-rpc.warn"

      # @!attribute instrumenter
      #   @return [ Object ] The instrumenter
      attr_reader :instrumenter

      # Instrument and execute the provided block.
      #
      # @example Instrument and execute.
      #   instrument("bones-rpc.noop") do
      #     node.connect
      #   end
      #
      # @param [ String ] name The name of the operation.
      # @param [ Hash ] payload The payload.
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 0.0.1
      def instrument(name, payload = {}, &block)
        instrumenter.instrument(name, payload, &block)
      end
    end
  end
end
