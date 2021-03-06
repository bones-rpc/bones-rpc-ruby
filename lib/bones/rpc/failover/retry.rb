# encoding: utf-8
module Bones
    module RPC
    module Failover

      # Retry is for the case when we get exceptions around the connection, and
      # want to make another attempt to try and resolve the issue.
      #
      # @since 0.0.1
      module Retry
        extend self

        # Executes the failover strategy. In the case of retyr, we disconnect and
        # reconnect, then try the operation one more time.
        #
        # @example Execute the retry strategy.
        #   Bones::RPC::Failover::Retry.execute(exception, node)
        #
        # @param [ Exception ] exception The raised exception.
        # @param [ Node ] node The node the exception got raised on.
        #
        # @raise [ Errors::ConnectionFailure ] If the retry fails.
        #
        # @return [ Object ] The result of the block yield.
        #
        # @since 0.0.1
        def execute(exception, node)
          node.disconnect
          begin
            yield if block_given?
          rescue Exception => e
            node.down
            raise(e)
          end
        end
      end
    end
  end
end
