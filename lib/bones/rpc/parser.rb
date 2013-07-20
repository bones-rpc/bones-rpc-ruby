# encoding: utf-8
require 'bones/rpc/parser/buffer'

module Bones
  module RPC
    class Parser

      EXT8  = [0xC7].pack('C').freeze
      EXT16 = [0xC8].pack('C').freeze
      EXT32 = [0xC9].pack('C').freeze

      attr_reader :stream, :adapter

      def buffer
        @buffer ||= Bones::RPC::Parser::Buffer.new(@stream)
      end

      def initialize(stream, adapter)
        @stream = stream.force_encoding('BINARY')
        @adapter = Adapter.get(adapter)
      end

      def parser
        @parser ||= @adapter.parser(@stream)
      end

      def read
        sync do
          b = buffer.getc
          buffer.ungetc(b)
          if b.nil?
            raise EOFError
          elsif b.start_with?(EXT8)
            buffer.skip(1)
            len, = buffer.read(1).unpack('C')
            type, = buffer.read(1).unpack('C')
            check_ext!(type)
            head, = buffer.read(1).unpack('C')
            data = buffer.read(len-1)
            parse_ext!(head, data)
          elsif b.start_with?(EXT16)
            buffer.skip(1)
            len, = buffer.read(2).unpack('n')
            type, = buffer.read(1).unpack('C')
            check_ext!(type)
            head, = buffer.read(1).unpack('C')
            data = buffer.read(len-1)
            parse_ext!(head, data)
          elsif b.start_with?(EXT32)
            buffer.skip(1)
            len, = buffer.read(4).unpack('N')
            type, = buffer.read(1).unpack('C')
            check_ext!(type)
            head, = buffer.read(1).unpack('C')
            data = buffer.read(len-1)
            parse_ext!(head, data)
          else
            object = parser.read
            buffer.seek(parser.unpacker_pos)
            map_from!(object)
          end
        end
      end

      private

      def check_ext!(type)
        raise(Errors::InvalidExtMessage, "bad ext message received of type #{type.inspect} (should be #{0x0D.inspect})") unless valid_ext?(type)
      end

      def map_from!(object)
        case object
        when Array
          if (3..4).include?(object.size)
            case object.first
            when 0
              Protocol::Request.map_from(object)
            when 1
              Protocol::Response.map_from(object)
            when 2
              Protocol::Notify.map_from(object)
            else
              object
            end
          end
        else
          object
        end
      end

      def parse_ext!(head, data)
        message = Protocol.get_by_ext_head(head)
        if message
          message.unpack(data)
        else
          map_from!(Adapter.get_by_ext_head(head).unpack(data))
        end
      end

      def sync
        buffer.transaction do
          yield
        end
      ensure
        parser.unpacker_seek(buffer.pos) if parser.unpacker_pos != buffer.pos
      end

      def valid_ext?(type)
        type == 0x0D
      end

    end
  end
end
