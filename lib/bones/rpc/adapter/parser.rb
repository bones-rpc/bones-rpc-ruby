# encoding: utf-8
module Bones
  module RPC
    module Adapter
      class Parser

        attr_reader :adaper, :data

        def initialize(adapter, data)
          @adapter = Adapter.get(adapter)
          @data = data
        end

        def packer
          @packer ||= @adapter.packer(data)
        end

        def read
          unpacker.read
        end

        def unpacker_seek(n)
          @adapter.unpacker_seek(self, n)
        end

        def unpacker
          @unpacker ||= @adapter.unpacker(data)
        end

        def unpacker_pos
          @adapter.unpacker_pos(self)
        end

      end
    end
  end
end
