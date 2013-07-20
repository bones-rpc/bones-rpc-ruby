# encoding: utf-8
module Bones
  module RPC
    module Protocol
      class Synchronize < ExtMessage

        uint32 :id
        binary :adapter

        finalize

        def initialize(id, adapter)
          self.id = id
          self.adapter = adapter
        end

        undef ext_head
        undef :adapter=
        undef serialize_adapter

        def ext_head
          0
        end

        def adapter=(adapter)
          @adapter = Adapter.get(adapter)
        end

        def deserialize_adapter(buffer)
          self.adapter = buffer.read(ext_length - 5)
        end

        def serialize_adapter(buffer)
          buffer << adapter.adapter_name.to_s
        end

        def log_inspect
          type = "SYNCHRONIZE"
          fields = []
          fields << ["%-12s", type]
          fields << ["id=%s", id]
          fields << ["adapter=%s", adapter]
          f, v = fields.transpose
          f.join(" ") % v
        end

        def self.deserialize(buffer, adapter = nil)
          message = super
          message.deserialize_id(buffer)
          message.deserialize_adapter(buffer)
          message
        end

        def self.unpack(data)
          buffer = StringIO.new(data)
          id, = buffer.read(4).unpack('N')
          adapter = buffer.read
          new(id, adapter)
        end

        def store(node, socket, future)
          node.future_store(socket, :synack, id, future)
        end

        Protocol.register_ext_head self, 0

      end
    end
  end
end
