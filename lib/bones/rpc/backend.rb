# encoding: utf-8
module Bones
  module RPC
    module Backend
      extend self

      def get(backend_name)
        backends[backend_name] || raise(Errors::InvalidBackend, "Unknown backend #{backend_name.inspect}")
      end

      def register(backend)
        backend.send(:attr_reader, :backend_name)
        backend.send(:include, Backend::Base)
        backend.send(:extend, backend)
        backends[backend] ||= backend
        backends[backend.backend_name] ||= backend
        backends[backend.backend_name.to_s] ||= backend
        return backend
      end

      private

      def backends
        @backends ||= {}
      end
    end
  end
end

require 'bones/rpc/backend/base'
require 'bones/rpc/backend/synchronous'
