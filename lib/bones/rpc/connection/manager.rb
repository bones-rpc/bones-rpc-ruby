# encoding: utf-8
module Bones
  module RPC
    class Connection

      # This class contains behaviour of connection pools for specific addresses.
      #
      # @since 2.0.0
      module Manager
        extend self

        # Used for synchronization of pools access.
        MUTEX = Mutex.new

        def node(address, options)
          MUTEX.synchronize do
            nodes[address.resolved] ||=
              Node.new(address, options)
          end
        end

        # Get a connection pool for the provided node.
        #
        # @example Get a connection pool for the node.
        #   Manager.pool(node)
        #
        # @param [ Node ] The node.
        #
        # @return [ Pool ] The connection pool for the Node.
        #
        # @since 2.0.0
        def pool(node)
          MUTEX.synchronize do
            pools[node.id] ||=
              Pool.new(node)
          end
        end

        private

        def nodes
          @nodes ||= {}
        end

        # Get all the connection pools. This is a cache that stores each pool
        # with lookup by it's resolved address.
        #
        # @api private
        #
        # @example Get the pools.
        #   Manager.pools
        #
        # @return [ Hash ] The cache of pools.
        #
        # @since 2.0.0
        def pools
          @pools ||= {}
        end
      end
    end
  end
end
