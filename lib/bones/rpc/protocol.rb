module Bones #:nodoc:
  module RPC

    # The +Bones::RPC::Protocol+ namespace contains convenience classes for
    # building all of the possible messages defined in the Bones RPC Protocol.
    module Protocol
      extend self

      def get_by_ext_head(head)
        ext_heads[head]
      end

      def register_ext_head(message, head)
        ext_heads[head] ||= message
        return message
      end

      private

      def ext_heads
        @ext_heads ||= {}
      end
    end
  end
end

require 'bones/rpc/protocol/adapter_helper'
require 'bones/rpc/protocol/binary_helper'

require 'bones/rpc/protocol/ext_message'
require 'bones/rpc/protocol/acknowledge'
require 'bones/rpc/protocol/synchronize'

require 'bones/rpc/protocol/notify'
require 'bones/rpc/protocol/request'
require 'bones/rpc/protocol/response'

module Bones
  module RPC
    module Protocol

      def deserialize(buffer, adapter = nil)
        char = buffer.getc
        buffer.ungetc(char)
        if sub = MAP[char]
          sub.deserialize(buffer, adapter)
        elsif adapter
          Adapter.get(adapter).deserialize(buffer)
        else
          raise NotImplementedError, "Unknown data received: #{char.inspect}"
        end
      end

      module MessagePackExtended
        extend self

        def deserialize(buffer, adapter = nil)
          ext8 = buffer.getc
          len = buffer.getc
          type = buffer.getc
          buffer.ungetc(type)
          buffer.ungetc(len)
          buffer.ungetc(ext8)
          if sub = MAP[type]
            sub.deserialize(buffer, adapter)
          else
            raise NotImplementedError, "Unknown MessagePackExtended data received: {ext8: #{ext8.inspect}, len: #{len.inspect}, type: #{type.inspect}}"
          end
        end

        module BonesRPC
          extend self

          def deserialize(buffer, adapter = nil)
            ext8 = buffer.getc
            len = buffer.getc
            type = buffer.getc
            head = buffer.getc
            buffer.ungetc(head)
            buffer.ungetc(type)
            buffer.ungetc(len)
            buffer.ungetc(ext8)
            if sub = MAP[head]
              sub.deserialize(buffer, adapter)
            else
              raise NotImplementedError, "Unknown BonesRPC data received: {ext8: #{ext8.inspect}, len: #{len.inspect}, type: #{type.inspect}, head: #{head.inspect}}"
            end
          end

          MAP = {
            [0].pack('C').freeze => Synchronize,
            [1].pack('C').freeze => Acknowledge
          }.freeze
        end

        MAP = {
          [0x0d].pack('C').freeze => BonesRPC
        }.freeze
      end

      MAP = {
        [0xc7].pack('C').freeze => MessagePackExtended
      }.freeze
    end
  end
end
