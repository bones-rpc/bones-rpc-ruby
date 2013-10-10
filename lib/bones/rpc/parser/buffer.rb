# encoding: utf-8
module Bones
  module RPC
    class Parser
      class Buffer

        attr_reader :io

        def initialize(data)
          @io = data.is_a?(StringIO) ? data : StringIO.new(data)
        end

        def getbyte
          io.getbyte
        end

        def getc
          io.getc
        end

        def pos
          io.pos
        end

        def read(n)
          i = pos
          data = io.read(n)
          if data.nil? || data.bytesize < n
            seek(i)
            raise EOFError
          else
            data
          end
        end

        def rewind
          io.rewind
        end

        def seek(pos)
          io.seek(pos)
        end

        def size
          io.size
        end

        def skip(n)
          seek(pos + n)
        end

        def sync(*others)
          yield
        ensure
          others.each { |other| other.seek(pos) }
        end

        def to_str
          i = pos
          begin
            io.read || ""
          ensure
            seek(i)
          end
        end

        def transaction
          i = pos
          begin
            yield
          rescue EOFError => e
            seek(i)
            raise e
          end
        end

        def ungetc(c)
          io.ungetc(c)
        end

      end
    end
  end
end
