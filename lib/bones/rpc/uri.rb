# encoding: utf-8
module Bones
  module RPC

    # Parses Bones::RPC uri
    #
    # @since 0.0.1
    class Uri

      # Get the scheme pattern.
      #
      # @since 0.0.1
      SCHEME = /(bones-rpc:\/\/)/

      # The user name pattern.
      #
      # @since 0.0.1
      USER = /([-.\w:]+)/

      # The password pattern.
      #
      # @since 0.0.1
      PASS = /([^@,]+)/

      # The nodes pattern.
      #
      # @since 0.0.1
      NODES = /((([-.\w]+)(?::(\w+))?,?)+)/

      # The database pattern.
      #
      # @since 0.0.1
      DATABASE = /(?:\/([-\w]+))?/

      # The options pattern.
      #
      # @since 0.0.1
      OPTIONS  = /(?:\?(.+))/

      # The full URI pattern.
      #
      # @since 0.0.1
      URI = /#{SCHEME}(#{USER}:#{PASS}@)?#{NODES}#{DATABASE}#{OPTIONS}?/

      # The options that have to do with write concerns.
      #
      # @since 0.0.1
      WRITE_OPTIONS = [ "w", "j", "fsync", "wtimeout" ].freeze

      # The mappings from read preferences in the URI to Bones::RPC's.
      #
      # @since 0.0.1
      READ_MAPPINGS = {
        "nearest" => :nearest,
        "primary" => :primary,
        "primarypreferred" => :primary_preferred,
        "secondary" => :secondary,
        "secondarypreferred" => :secondary_preferred
      }.freeze

      # @!attribute match
      #   @return [ Array ] The uri match.
      attr_reader :match

      # Helper to determine if authentication is provided
      #
      # @example Boolean response if username/password given
      #   uri.auth_provided?
      #
      # @return [ true, false ] If authorization is provided.
      #
      # @since 0.0.1
      def auth_provided?
        !username.nil? && !password.nil?
      end

      # Get the database provided in the URI.
      #
      # @example Get the database.
      #   uri.database
      #
      # @return [ String ] The database.
      #
      # @since 0.0.1
      def database
        @database ||= match[9]
      end

      # Get the hosts provided in the URI.
      #
      # @example Get the hosts.
      #   uri.hosts
      #
      # @return [ Array<String> ] The hosts.
      #
      # @since 0.0.1
      def hosts
        @hosts ||= match[5].split(",")
      end

      # Create the new uri from the provided string.
      #
      # @example Create the new uri.
      #   Bones::RPC::Uri.new(uri)
      #
      # @param [ String ] string The uri string.
      #
      # @since 0.0.1
      def initialize(string)
        @match = string.match(URI)
        invalid_uri!(string) unless @match
      end

      # Raise a human readable error when improper URI provided
      #
      # @example Raise error and provide guidance on invalid URI
      #   Bones::RPC::Uri.invalid!(uri)
      #
      # @param [ String ] Invalid string
      #
      # @since 0.0.1
      def invalid_uri!(string)
        scrubbed = string.gsub(/[^:]+@/, '<password>@')
        raise Errors::InvalidBonesRPCURI, "The provided connection string is not a value URI: #{scrubbed}"
      end

      # Get the options provided in the URI.
      #
      # @example Get the options
      #   uri.options
      #
      # @note The options provided in the URI string must match the Bones::RPC
      #   specification.
      #
      # @return [ Hash ] Options hash usable by Moped
      #
      # @since 0.0.1
      def options
        options_string, options = match[10], {}
        unless options_string.nil?
          options_string.split(/\&/).each do |option_string|
            key, value = option_string.split(Regexp.new('='))
            if WRITE_OPTIONS.include?(key)
              options[:write] = { key.to_sym => cast(value) }
            elsif read = READ_MAPPINGS[value.downcase]
              options[:read] = read
            else
              options[key.to_sym] = cast(value)
            end
          end
        end
        options
      end

      # Get the password provided in the URI.
      #
      # @example Get the password.
      #   uri.password
      #
      # @return [ String ] The password.
      #
      # @since 0.0.1
      def password
        @password ||= match[4]
      end

      # Get the uri as a Bones::RPC friendly configuration hash.
      #
      # @example Get the uri as a hash.
      #   uri.to_hash
      #
      # @return [ Hash ] The uri as options.
      #
      # @since 0.0.1
      def to_hash
        config = { database: database, hosts: hosts }
        if username && password
          config.merge!(username: username, password: password)
        end
        config
      end

      # Create Bones::RPC usable arguments
      #
      # @example Get the bones_rpc args
      #   uri.bones_rpc_arguments
      #
      # @return [ Array ] Array of arguments usable by bones_rpc
      #
      # @since 0.0.1
      def bones_rpc_arguments
        [ hosts, options ]
      end

      # Get the username provided in the URI.
      #
      # @example Get the username.
      #   uri.username
      #
      # @return [ String ] The username.
      #
      # @since 0.0.1
      def username
        @username ||= match[3]
      end

      private

      def cast(value)
        if value == "true"
          true
        elsif value == "false"
          false
        elsif value =~ /[\d]/
          value.to_i
        else
          value.to_sym
        end
      end
    end
  end
end
