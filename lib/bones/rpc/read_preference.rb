# encoding: utf-8
require 'bones/rpc/read_preference/selectable'
require 'bones/rpc/read_preference/nearest'

module Bones
  module RPC

    # Provides behaviour around getting various read preference implementations.
    #
    # @since 2.0.0
    module ReadPreference
      extend self

      # Hash lookup for the read preference classes based off the symbols
      # provided in configuration.
      #
      # @since 2.0.0
      PREFERENCES = {
        nearest: Nearest
      }.freeze

      # Get a read preference for the provided name. Valid names are:
      #   - :nearest
      #   - :primary
      #   - :primary_preferred
      #   - :secondary
      #   - :secondary_preferred
      #
      # @example Get the primary read preference.
      #   Bones::RPC::ReadPreference.get(:primary)
      #
      # @param [ Symbol ] name The name of the preference.
      # @param [ Array<Hash> ] tags The tag sets to match the node on.
      #
      # @return [ Object ] The appropriate read preference.
      #
      # @since 2.0.0
      def get(name, tags = nil)
        PREFERENCES.fetch(name.to_sym).new(tags)
      end
    end
  end
end
