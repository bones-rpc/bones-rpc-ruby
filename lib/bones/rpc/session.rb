# encoding: utf-8
require 'bones/rpc/read_preference'
require 'bones/rpc/readable'
require 'bones/rpc/cluster'
require 'bones/rpc/context'

module Bones
  module RPC

    # A session in bones_rpc is root for all interactions with a Bones::RPC server or
    # replica set.
    #
    # It can talk to a single default database, or dynamically speak to multiple
    # databases.
    #
    # @example Single database (console-style)
    #   session = Bones::RPC::Session.new(["127.0.0.1:27017"])
    #   session.use(:bones_rpc)
    #   session[:users].find.one
    #
    # @example Multiple databases
    #   session = Bones::RPC::Session.new(["127.0.0.1:27017"])
    #   session.with(database: :admin) do |admin|
    #     admin.command(ismaster: 1)
    #   end
    #
    # @example Authentication
    #   session = Bones::RPC::Session.new %w[127.0.0.1:27017],
    #   session.with(database: "admin").login("admin", "s3cr3t")
    #
    # @since 1.0.0
    class Session
      include Optionable

      # @!attribute cluster
      #   @return [ Cluster ] The cluster of nodes.
      # @!attribute options
      #   @return [ Hash ] The configuration options.
      attr_reader :cluster, :options

      # Run +command+ on the current database.
      #
      # @param (see Bones::RPC::Database#command)
      #
      # @return (see Bones::RPC::Database#command)
      #
      # @since 1.0.0
      def command(op)
        current_database.command(op)
      end

      def context
        @context ||= Context.new(self)
      end

      # Disconnects all nodes in the session's cluster. This should only be used
      # in cases # where you know you're not going to use the cluster on the
      # thread anymore and need to force the connections to close.
      #
      # @return [ true ] True if the disconnect succeeded.
      #
      # @since 1.2.0
      def disconnect
        cluster.disconnect
      end

      # Provide a string inspection for the session.
      #
      # @example Inspect the session.
      #   session.inspect
      #
      # @return [ String ] The string inspection.
      #
      # @since 1.4.0
      def inspect
        "<#{self.class.name} seeds=#{cluster.seeds}>"
      end

      # Setup validation of allowed read preference options.
      #
      # @since 2.0.0
      option(:read).allow(
        :nearest
      )

      # Setup validation of allowed database options. (Any string or symbol)
      #
      # @since 2.0.0
      option(:adapter).allow(Optionable.any(String), Optionable.any(Symbol), Optionable.any(Module))

      # Setup validation of allowed max retry options. (Any integer)
      #
      # @since 2.0.0
      option(:max_retries).allow(Optionable.any(Integer))

      # Setup validation of allowed pool size options. (Any integer)
      #
      # @since 2.0.0
      option(:pool_size).allow(Optionable.any(Integer))

      # Setup validation of allowed retry interval options. (Any numeric)
      #
      # @since 2.0.0
      option(:retry_interval).allow(Optionable.any(Numeric))

      # Setup validation of allowed reap interval options. (Any numeric)
      #
      # @since 2.0.0
      option(:reap_interval).allow(Optionable.any(Numeric))

      # Setup validation of allowed ssl options. (Any boolean)
      #
      # @since 2.0.0
      option(:ssl).allow(true, false)

      # Setup validation of allowed timeout options. (Any numeric)
      #
      # @since 2.0.0
      option(:timeout).allow(Optionable.any(Numeric))

      # Initialize a new database session.
      #
      # @example Initialize a new session.
      #   Session.new([ "localhost:27017" ])
      #
      # @param [ Array ] seeds An array of host:port pairs.
      # @param [ Hash ] options The options for the session.
      #
      # @see Above options validations for allowed values in the options hash.
      #
      # @since 1.0.0
      def initialize(seeds, options = {})
        validate_strict(options)
        @options = options
        @cluster = Cluster.new(self, seeds, options)
      end

      def notify(method, *params)
        context.notify(method, params)
      end

      def on_connect(socket)
      end

      def on_message(message)
      end

      # Get the read preference for the session. Will default to primary if none
      # was provided.
      #
      # @example Get the session's read preference.
      #   session.read_preference
      #
      # @return [ Object ] The read preference.
      #
      # @since 2.0.0
      def read_preference
        @read_preference ||= ReadPreference.get(options[:read] || :nearest)
      end

      def request(method, *params)
        context.request(method, params)
      end

      def synchronize
        context.synchronize
      end

      class << self

        # Create a new session from a URI.
        #
        # @example Initialize a new session.
        #   Session.connect("bones-rpc://localhost:27017/my_db")
        #
        # @param [ String ] Bones::RPC URI formatted string.
        #
        # @return [ Session ] The new session.
        #
        # @since 3.0.0
        def connect(uri)
          uri = Uri.new(uri)
          session = new(*uri.bones_rpc_arguments)
          session
        end
      end

      private

      def initialize_copy(_)
        @options = @options.dup
        @read_preference = nil
      end
    end
  end
end
