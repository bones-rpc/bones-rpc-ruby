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

      def read_ext(buffer)
        ext_code, = buffer.read(1).unpack('C')
        ext_length, = case ext_code
        when 0xC7
          buffer.read(1).unpack('C')
        when 0xC8
          buffer.read(2).unpack('n')
        when 0xC9
          buffer.read(4).unpack('N')
        end
        ext_type, = buffer.read(1).unpack('c')
        ext_data = buffer.read(ext_length)
        return ext_data
      end

      def write_ext(head, data, buffer = "")
        ext_length = data.bytesize + 1
        ext_code = if ext_length <= 0xFF
          0xC7
        elsif ext_length <= 0xFFFF
          0xC8
        elsif ext_length <= 0xFFFFFFFF
          0xC9
        else
          raise ArgumentError, "datasize too large: #{ext_length} (max #{0xFFFFFFFF} bytes)"
        end
        buffer << [ext_code].pack('C')
        ext_length_packer = case ext_code
        when 0xC7
          'C'
        when 0xC8
          'n'
        when 0xC9
          'N'
        else
          raise ArgumentError, "bad ext_code: #{ext_code} (should be one of #{0xC7}, #{0xC8}, #{0xC9})"
        end
        buffer << [ext_length].pack(ext_length_packer)
        ext_type = 0x0D
        buffer << [ext_type].pack('c')
        buffer << [head].pack('C')
        buffer << data.force_encoding('BINARY')
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
