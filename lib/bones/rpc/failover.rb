# encoding: utf-8
require 'bones/rpc/failover/disconnect'
require 'bones/rpc/failover/ignore'
require 'bones/rpc/failover/retry'

module Bones
  module RPC

    # Provides behaviour around failover scenarios for different types of
    # exceptions that get raised on connection and execution of operations.
    #
    # @since 0.0.1
    module Failover
      extend self

      # Hash lookup for the failover classes based off the exception type.
      #
      # @since 0.0.1
      STRATEGIES = {
        Errors::ConnectionFailure => Retry
      }.freeze

      # Get the appropriate failover handler given the provided exception.
      #
      # @example Get the failover handler for an IOError.
      #   Bones::RPC::Failover.get(IOError)
      #
      # @param [ Exception ] exception The raised exception.
      #
      # @return [ Object ] The failover handler.
      #
      # @since 0.0.1
      def get(exception)
        STRATEGIES.fetch(exception.class, Disconnect)
      end
    end
  end
end
