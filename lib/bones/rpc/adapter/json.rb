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

        Adapter.register self
      end
    end
  end
end
