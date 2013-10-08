# encoding: utf-8
module Bones
  module RPC

    # Provides behaviour around readable objects.
    #
    # @since 0.0.1
    module Readable

      private

      # Convenience method for getting the cluster from the session.
      #
      # @api private
      #
      # @example Get the cluster from the session.
      #   database.cluster
      #
      # @return [ Cluster ] The cluster.
      #
      # @since 0.0.1
      def cluster
        session.cluster
      end

      # Convenience method for getting the read preference from the session.
      #
      # @api private
      #
      # @example Get the read preference.
      #   database.read_preference
      #
      # @return [ Object ] The session's read preference.
      #
      # @since 0.0.1
      def read_preference
        session.read_preference
      end

      # Get the query options from the read preference.
      #
      # @api private
      #
      # @example Get the query options.
      #   database.query_options
      #
      # @param [ Hash ] options The existing options on the query.
      #
      # @return [ Hash ] The new query options.
      #
      # @since 0.0.1
      def query_options(options = {})
        read_preference.query_options(options)
      end
    end
  end
end
