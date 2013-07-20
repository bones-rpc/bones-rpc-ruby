# encoding: utf-8
module Bones
  module RPC
    module Protocol
      class Acknowledge < ExtMessage

        uint32 :id
        uint8 :ready

        finalize

        def initialize(id, ready)
          self.id = id
          self.ready = ready
        end

        undef ext_head
        undef ready
        undef :ready=
        undef serialize_ready

        def ext_head
          1
        end

        def ready
          @ready
        end

        def ready=(val)
          @ready = case val
          when 0xC2
            false
          when 0xC3
            true
          else
            !!val
          end
        end

        def serialize_ready(buffer)
          buffer << [ready ? 0xC3 : 0xC2].pack('C')
        end

        def log_inspect
          type = "ACKNOWLEDGE"
          fields = []
          fields << ["%-12s", type]
          fields << ["id=%s", id]
          fields << ["ready=%s", ready]
          f, v = fields.transpose
          f.join(" ") % v
        end

        def self.deserialize(buffer, adapter = nil)
          message = super
          message.deserialize_id(buffer)
          message.deserialize_ready(buffer)
          message
        end

        def self.unpack(data)
          buffer = StringIO.new(data)
          id, = buffer.read(4).unpack('N')
          ready = buffer.read(1)
          new(id, ready)
        end

        def get(node, socket)
          node.future_get(socket, :synack, id)
        end

        def signal(future)
          future.signal(FutureValue.new(self))
        end

        Protocol.register_ext_head self, 1

      end
    end
  end
end
