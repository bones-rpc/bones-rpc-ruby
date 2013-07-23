# encoding: utf-8
require 'bones/rpc/node'

module Bones
  module RPC

    # The cluster represents a cluster of MongoDB server nodes, either a single
    # node, a replica set, or a mongos server.
    #
    # @since 1.0.0
    class Cluster

      # The default interval that a node would be flagged as "down".
      #
      # @since 2.0.0
      DOWN_INTERVAL = 30

      # The default interval that a node should be refreshed in.
      #
      # @since 2.0.0
      REFRESH_INTERVAL = 300

      # The default time to wait to retry an operation.
      #
      # @since 2.0.0
      RETRY_INTERVAL = 0.25

      # @!attribute options
      #   @return [ Hash ] The refresh options.
      # @!attribute peers
      #   @return [ Array<Node> ] The node peers.
      # @!attribute seeds
      #   @return [ Array<Node> ] The seed nodes.
      attr_reader :session, :peers, :seeds

      # Disconnects all nodes in the cluster. This should only be used in cases
      # where you know you're not going to use the cluster on the thread anymore
      # and need to force the connections to close.
      #
      # @return [ true ] True if the disconnect succeeded.
      #
      # @since 1.2.0
      def disconnect
        nodes.each { |node| node.disconnect } and true
      end

      # Get the interval at which a node should be flagged as down before
      # retrying.
      #
      # @example Get the down interval, in seconds.
      #   cluster.down_interval
      #
      # @return [ Integer ] The down interval.
      #
      # @since 1.2.7
      def down_interval
        @down_interval ||= options[:down_interval] || DOWN_INTERVAL
      end

      def handle_socket(node, socket)
        session.handle_socket(node, socket)
      end

      # Initialize the new cluster.
      #
      # @example Initialize the cluster.
      #   Cluster.new([ "localhost:27017" ], down_interval: 20)
      #
      # @param [ Hash ] options The cluster options.
      #
      # @option options :down_interval number of seconds to wait before attempting
      #   to reconnect to a down node. (30)
      # @option options :refresh_interval number of seconds to cache information
      #   about a node. (300)
      # @option options [ Integer ] :timeout The time in seconds to wait for an
      #   operation to timeout. (5)
      #
      # @since 1.0.0
      def initialize(session, hosts)
        @session = session
        @seeds = hosts.map { |host| Node.new(self, Address.new(host)) }
        @peers = []
      end

      # Provide a pretty string for cluster inspection.
      #
      # @example Inspect the cluster.
      #   cluster.inspect
      #
      # @return [ String ] A nicely formatted string.
      #
      # @since 1.0.0
      def inspect
        "#<#{self.class.name}:#{object_id} @seeds=#{seeds.inspect}>"
      end

      # Get the number of times an operation should be retried before raising an
      # error.
      #
      # @example Get the maximum retries.
      #   cluster.max_retries
      #
      # @return [ Integer ] The max retries.
      #
      # @since 1.2.7
      def max_retries
        @max_retries ||= options[:max_retries] || seeds.size
      end

      # Returns the list of available nodes, refreshing 1) any nodes which were
      # down and ready to be checked again and 2) any nodes whose information is
      # out of date. Arbiter nodes are not returned.
      #
      # @example Get the available nodes.
      #   cluster.nodes
      #
      # @return [ Array<Node> ] the list of available nodes.
      #
      # @since 1.0.0
      def nodes
        # Find the nodes that were down but are ready to be refreshed, or those
        # with stale connection information.
        needs_refresh, available = seeds.partition do |node|
          refreshable?(node)
        end

        # Refresh those nodes.
        available.concat(refresh(needs_refresh))

        # Now return all the nodes that are available and participating in the
        # replica set.
        available.reject{ |node| node.down? }
      end

      def options
        session.options
      end

      def pool_size
        options[:pool_size] || 5
      end

      # Refreshes information for each of the nodes provided. The node list
      # defaults to the list of all known nodes.
      #
      # If a node is successfully refreshed, any newly discovered peers will also
      # be refreshed.
      #
      # @example Refresh the nodes.
      #   cluster.refresh
      #
      # @param [ Array<Node> ] nodes_to_refresh The nodes to refresh.
      #
      # @return [ Array<Node> ] the available nodes
      #
      # @since 1.0.0
      def refresh(nodes_to_refresh = seeds)
        refreshed_nodes = []
        seen = {}
        # Set up a recursive lambda function for refreshing a node and it's peers.
        refresh_node = ->(node) do
          unless seen[node]
            seen[node] = true
            # Add the node to the global list of known nodes.
            seeds.push(node) unless seeds.include?(node)
            begin
              node.refresh
              # This node is good, so add it to the list of nodes to return.
              refreshed_nodes.push(node) unless refreshed_nodes.include?(node)
            rescue Errors::ConnectionFailure
              # We couldn't connect to the node.
            end
          end
        end

        nodes_to_refresh.each(&refresh_node)
        refreshed_nodes
      end

      # Get the interval in which the node list should be refreshed.
      #
      # @example Get the refresh interval, in seconds.
      #   cluster.refresh_interval
      #
      # @return [ Integer ] The refresh interval.
      #
      # @since 1.2.7
      def refresh_interval
        @refresh_interval ||= options[:refresh_interval] || REFRESH_INTERVAL
      end

      # Get the operation retry interval - the time to wait before retrying a
      # single operation.
      #
      # @example Get the retry interval, in seconds.
      #   cluster.retry_interval
      #
      # @return [ Integer ] The retry interval.
      #
      # @since 1.2.7
      def retry_interval
        @retry_interval ||= options[:retry_interval] || RETRY_INTERVAL
      end

      private

      # Get the boundary where a node that is down would need to be refreshed.
      #
      # @api private
      #
      # @example Get the down boundary.
      #   cluster.down_boundary
      #
      # @return [ Time ] The down boundary.
      #
      # @since 2.0.0
      def down_boundary
        Time.new - down_interval
      end

      # Get the standard refresh boundary to discover new nodes.
      #
      # @api private
      #
      # @example Get the refresh boundary.
      #   cluster.refresh_boundary
      #
      # @return [ Time ] The refresh boundary.
      #
      # @since 2.0.0
      def refresh_boundary
        Time.new - refresh_interval
      end

      # Is the provided node refreshable? This is in the case where the refresh
      # boundary has passed, or the node has been down longer than the down
      # boundary.
      #
      # @api private
      #
      # @example Is the node refreshable?
      #   cluster.refreshable?(node)
      #
      # @param [ Node ] node The Node to check.
      #
      # @since 2.0.0
      def refreshable?(node)
        node.down? ? node.down_at < down_boundary : node.needs_refresh?(refresh_boundary)
      end

      # Creating a cloned cluster requires cloning all the seed nodes.
      #
      # @api prviate
      #
      # @example Clone the cluster.
      #   cluster.clone
      #
      # @return [ Cluster ] The cloned cluster.
      #
      # @since 1.0.0
      def initialize_copy(_)
        @seeds = seeds.map(&:dup)
      end
    end
  end
end
