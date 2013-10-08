# encoding: utf-8
module Bones
  module RPC
    module Adapter
      extend self

      def get(adapter_name)
        adapters[adapter_name] || raise(Errors::InvalidAdapter, "Unknown adapter #{adapter_name.inspect}")
      end

      def get_by_ext_head(head)
        ext_heads[head] || raise(Errors::InvalidExtMessage, "Unknown adapter for ext head #{head.inspect}")
      end

      def register(adapter)
        adapter.send(:attr_reader, :adapter_name)
        adapter.send(:include, Adapter::Base)
        adapter.send(:extend, adapter)
        adapters[adapter] ||= adapter
        adapters[adapter.adapter_name] ||= adapter
        adapters[adapter.adapter_name.to_s] ||= adapter
        return adapter
      end

      def register_ext_head(adapter, head)
        ext_heads[head] ||= adapter
        return adapter
      end

      private

      def adapters
        @adapters ||= {}
      end

      def ext_heads
        @ext_heads ||= {}
      end
    end
  end
end

require 'bones/rpc/adapter/parser'
require 'bones/rpc/adapter/base'
require 'bones/rpc/adapter/json'
