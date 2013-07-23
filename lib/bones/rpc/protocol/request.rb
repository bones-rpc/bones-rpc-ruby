# encoding: utf-8
module Bones
  module RPC
    module Protocol
      class Request
        include AdapterHelper

        integer :op_code
        integer :id
        binary :method
        list :params

        finalize

        def initialize(id, method, params)
          @id = id
          @method = method
          @params = params
        end

        undef op_code

        def op_code
          0
        end

        def log_inspect
          type = "REQUEST"
          fields = []
          fields << ["%-12s", type]
          fields << ["id=%s", id]
          fields << ["method=%s", method]
          fields << ["params=%s", params]
          f, v = fields.transpose
          f.join(" ") % v
        end

        def attach(node, future)
          node.attach(:request, id, future)
        end

      end
    end
  end
end
