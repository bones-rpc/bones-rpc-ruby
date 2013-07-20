# encoding: utf-8
require 'erlang/etf'

module Bones
  module RPC
    module Adapter
      module Erlang

        @adapter_name = :erlang

        def pack(message, buffer="")
          data = ::Erlang.term_to_binary(message)
          len = data.bytesize
          buffer << [len].pack('N')
          buffer << data
        end

        def unpack(buffer)
          len, = buffer.read(4).unpack('N')
          data = buffer.read(len)
          ::Erlang.binary_to_term(data)
        end

        Adapter.register self
      end
    end
  end
end
