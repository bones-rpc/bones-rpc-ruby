# encoding: utf-8
require 'bones/rpc/node'
require 'bones/rpc/synchronous/connection'
require 'bones/rpc/synchronous/future'
require 'thread'

module Bones
  module RPC
    module Synchronous

      # Represents a client to a node in a server cluster.
      #
      # @since 0.0.1
      class Node < ::Bones::RPC::Node
        # Compatability with Celluloid
        def abort(cause)
          raise cause
        end

        def async
          self
        end

        def current_actor
          self
        end

        def connection
          @mutex.synchronize do
            if block_given?
              yield @connection
            else
              @connection
            end
          end
        end

        def initialize(*args)
          @mutex = ::Mutex.new
          super(*args)
        end
      end
    end
  end
end
