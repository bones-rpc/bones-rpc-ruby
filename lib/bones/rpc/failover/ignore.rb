# encoding: utf-8
module Bones
  module RPC
    module Failover

      # Ignore is for the case when we get exceptions we deem are proper user
      # or datbase errors and should be re-raised.
      #
      # @since 0.0.1
      module Ignore
        extend self

        # Executes the failover strategy. In the case of ignore, we just re-raise
        # the exception that was thrown previously.
        #
        # @example Execute the ignore strategy.
        #   Bones::RPC::Failover::Ignore.execute(exception, node)
        #
        # @param [ Exception ] exception The raised exception.
        # @param [ Node ] node The node the exception got raised on.
        #
        # @raise [ Exception ] The exception that was previously thrown.
        #
        # @since 0.0.1
        def execute(exception, node)
          raise(exception)
        end
      end
    end
  end
end
