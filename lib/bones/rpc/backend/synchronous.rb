# encoding: utf-8
module Bones
  module RPC
    module Backend
      module Synchronous

        @backend_name = :synchronous

        def setup
          require 'bones/rpc/synchronous'
        end

        def connection_class
          ::Bones::RPC::Synchronous::Connection
        end

        def future_class
          ::Bones::RPC::Synchronous::Future
        end

        def node_class
          ::Bones::RPC::Synchronous::Node
        end

        Backend.register self
      end
    end
  end
end
