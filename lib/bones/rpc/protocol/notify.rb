# encoding: utf-8
module Bones
  module RPC
    module Protocol
      class Notify
        include AdapterHelper

        integer :op_code
        binary :method
        list :params

        finalize

        def initialize(method, params)
          @method = method
          @params = params
        end

        undef op_code

        def op_code
          2
        end

        def log_inspect
          type = "NOTIFY"
          fields = []
          fields << ["%-12s", type]
          fields << ["method=%s", method]
          fields << ["params=%s", params]
          f, v = fields.transpose
          f.join(" ") % v
        end

      end
    end
  end
end
