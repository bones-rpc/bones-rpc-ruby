# encoding: utf-8
module Bones
  module RPC
    module Adapter
      module Base

        def adapter_name
          raise NotImplementedError, "Adapter #{self.name} does not implement #adapter_name"
        end

        def deserialize(buffer = "")
          if buffer.is_a?(String)
            buffer = StringIO.new(buffer)
          end
          unpack(buffer)
        end

        def pack(message, buffer = "")
          raise NotImplementedError, "Adapter #{self.name} does not implement #pack"
        end

        def packer(buffer)
          raise NotImplementedError, "Adapter #{self.name} does not implement #packer"
        end

        def serialize(message, buffer = "")
          pack(message, buffer)
        end

        def unpack(buffer)
          raise NotImplementedError, "Adapter #{self.name} does not implement #unpack"
        end

        def unpacker(buffer)
          raise NotImplementedError, "Adapter #{self.name} does not implement #unpacker"
        end

      end
    end
  end
end
