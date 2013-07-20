# encoding: utf-8
module Bones
  module RPC
    module Protocol
      class ExtMessage
        include BinaryHelper

        uint8 :ext_code
        binary :ext_length
        int8 :ext_type
        uint8 :ext_head

        undef ext_code
        undef ext_length
        undef ext_type
        undef serialize_ext_length

        def ext_code
          @ext_code ||= begin
            len = datasize
            if len <= 0xFF
              0xC7
            elsif len <= 0xFFFF
              0xC8
            elsif len <= 0xFFFFFFFF
              0xC9
            else
              raise ArgumentError, "datasize too large: #{len} (max #{0xFFFFFFFF} bytes)"
            end
          end
        end

        def ext_length
          @ext_length ||= datasize + 1
        end

        def ext_type
          @ext_type ||= 0x0D
        end

        def deserialize_ext_length(buffer)
          self.ext_length, = case ext_code
          when 0xC7
            buffer.read(1).unpack('C')
          when 0xC8
            buffer.read(2).unpack('n')
          when 0xC9
            buffer.read(4).unpack('N')
          end
        end

        def serialize_ext_length(buffer)
          packer = case ext_code
          when 0xC7
            'C'
          when 0xC8
            'n'
          when 0xC9
            'N'
          end
          buffer << [ext_length].pack(packer)
        end

        def data
          (self.class.fields - ExtMessage.fields).inject("".force_encoding('BINARY')) do |buffer, field|
            send("serialize_#{field}", buffer)
          end
        end

        def datasize
          data.bytesize
        end

        def self.deserialize(buffer, adapter = nil)
          message = allocate
          message.deserialize_ext_code(buffer)
          message.deserialize_ext_length(buffer)
          message.deserialize_ext_type(buffer)
          message.deserialize_ext_head(buffer)
          message
        end

      end
    end
  end
end
