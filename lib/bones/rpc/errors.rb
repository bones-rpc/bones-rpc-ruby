# encoding: utf-8
module Bones
  module RPC
    module Errors

      # Raised when the connection pool is saturated and no new connection is
      # reaped during the wait time.
      class PoolSaturated < RuntimeError; end

      # Raised when attempting to checkout a connection on a thread that already
      # has a connection checked out.
      class ConnectionInUse < RuntimeError; end

      # Raised when attempting to checkout a pinned connection from the pool but
      # it is already in use by another object on the same thread.
      class PoolTimeout < RuntimeError; end

      # Generic error class for exceptions related to connection failures.
      class ConnectionFailure < StandardError; end

      # Raised when an Adapter is invalid.
      class InvalidAdapter < StandardError; end

      # Raised when a Bones::RPC URI is invalid.
      class InvalidBonesRPCURI < StandardError; end

      class InvalidExtMessage < StandardError; end

      # Tag applied to unhandled exceptions on a node.
      module SocketError; end
    end
  end
end
