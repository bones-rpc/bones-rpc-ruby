# encoding: utf-8
require 'json'

module Bones
  module RPC
    module Adapter
      module JSON

        @adapter_name = :json

        def pack(message, buffer="")
          buffer << ::JSON.dump(message)
        end

        def unpack(buffer)
          ::JSON.load(buffer)
        end

        def unpacker(data)
          Unpacker.new(data)
        end

        def parser(data)
          Adapter::Parser.new(self, data)
        end

        def unpacker_pos(parser)
          parser.unpacker.buffer.pos
        end

        def unpacker_seek(parser, n)
          parser.unpacker.buffer.seek(n)
          return n
        end

        # I apologize for how nasty this unpacker is; Oj or Yajl would be better fits
        class Unpacker
          attr_reader :buffer

          ARRAY_START = '['.freeze

          def initialize(data)
            @buffer = Bones::RPC::Parser::Buffer.new(data)
          end

          def read
            if skip_to_array_start
              unpack_stream("", buffer.pos)
            else
              nil
            end
          end

          private

          def unpack_stream(temp, pos)
            if char = buffer.getc
              temp << char
              term = begin
                ::JSON.load(temp)
              rescue ::JSON::ParserError
                unpack_stream(temp, pos)
              end
              return term
            else
              buffer.seek(pos)
              return nil
            end
          end

          def skip_to_array_start
            i = buffer.pos
            case buffer.getc
            when ARRAY_START
              buffer.seek(i)
              return true
            when nil
              return false
            else
              skip_to_array_start
            end
          end
        end

        Adapter.register self
      end
    end
  end
end
