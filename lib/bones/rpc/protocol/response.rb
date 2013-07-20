# encoding: utf-8
module Bones
  module RPC
    module Protocol
      class Response
        include AdapterHelper

        integer :op_code
        integer :id
        any :error
        any :result

        finalize

        def initialize(id, error, result)
          @id = id
          @error = error
          @result = result
        end

        undef op_code

        def op_code
          @op_code ||= 1
        end

        def log_inspect
          type = "RESPONSE"
          fields = []
          fields << ["%-12s", type]
          fields << ["id=%s", id]
          fields << ["error=%s", error]
          fields << ["result=%s", result]
          f, v = fields.transpose
          f.join(" ") % v
        end

        def self.map_from(object)
          message = allocate
          message.op_code = object[0]
          message.id = object[1]
          message.error = object[2]
          message.result = object[3]
          message
        end

        def get(node, socket)
          node.future_get(socket, :request, id)
        end

        def signal(future)
          future.signal(FutureValue.new(self))
        end

      end
    end
  end
end
