# encoding: utf-8
module Bones
  module RPC

    # The class for interacting with a MongoDB database. One only interacts with
    # this class indirectly through a session.
    #
    # @since 1.0.0
    class Context
      include Readable

      # @!attribute session
      #   @return [ Session ] The database session.
      attr_reader :session

      # Initialize the database.
      #
      # @example Initialize a database object.
      #   Database.new(session, :artists)
      #
      # @param [ Session ] session The session.
      # @param [ String, Symbol ] name The name of the database.
      #
      # @since 1.0.0
      def initialize(session)
        @session = session
      end

      def notify(method, params)
        read_preference.with_node(cluster) do |node|
          node.notify(method, params)
        end
      end

      def request(method, params)
        read_preference.with_node(cluster) do |node|
          node.request(method, params)
        end
      end

      def synchronize
        read_preference.with_node(cluster) do |node|
          node.synchronize
        end
      end
    end
  end
end
