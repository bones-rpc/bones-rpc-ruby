# encoding: utf-8
module Bones
  module RPC

    # Contains behaviour for logging.
    #
    # @since 0.0.1
    module Loggable

      # Log the provided operations.
      #
      # @example Log the operations.
      #   Loggable.log_operations("BONES-RPC", {}, 30)
      #
      # @param [ String ] prefix The prefix for all operations in the log.
      # @param [ Array ] ops The operations.
      # @param [ String ] runtime The runtime in formatted ms.
      #
      # @since 0.0.1
      def self.log_operations(prefix, ops, runtime)
        indent  = " "*prefix.length
        if ops.length == 1
          Bones::RPC.logger.debug([ prefix, ops.first.log_inspect, "runtime: #{runtime}" ].join(' '))
        else
          first, *middle, last = ops
          Bones::RPC.logger.debug([ prefix, first.log_inspect ].join(' '))
          middle.each { |m| Bones::RPC.logger.debug([ indent, m.log_inspect ].join(' ')) }
          Bones::RPC.logger.debug([ indent, last.log_inspect, "runtime: #{runtime}" ].join(' '))
        end
      end

      # Log the payload to debug.
      #
      # @example Log to debug.
      #   Loggable.debug("BONES-RPC", payload "30.012ms")
      #
      # @param [ String ] prefix The log prefix.
      # @param [ String ] payload The log operations.
      # @param [ String ] runtime The runtime in formatted ms.
      #
      # @since 0.0.1
      def self.debug(prefix, payload, runtime)
        Bones::RPC.logger.debug([ prefix, payload, "runtime: #{runtime}" ].join(' '))
      end

      # Log the payload to warn.
      #
      # @example Log to warn.
      #   Loggable.warn("BONES-RPC", payload "30.012ms")
      #
      # @param [ String ] prefix The log prefix.
      # @param [ String ] payload The log operations.
      # @param [ String ] runtime The runtime in formatted ms.
      #
      # @since 0.0.1
      def self.warn(prefix, payload, runtime)
        Bones::RPC.logger.warn([ prefix, payload, "runtime: #{runtime}" ].join(' '))
      end

      # Get the logger.
      #
      # @example Get the logger.
      #   Loggable.logger
      #
      # @return [ Logger ] The logger.
      #
      # @since 0.0.1
      def logger
        return @logger if defined?(@logger)
        @logger = rails_logger || default_logger
      end

      # Get the rails logger.
      #
      # @example Get the rails logger.
      #   Loggable.rails_logger
      #
      # @return [ Logger ] The Rails logger.
      #
      # @since 0.0.1
      def rails_logger
        defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      end

      # Get the default logger.
      #
      # @example Get the default logger.
      #   Loggable.default_logger
      #
      # @return [ Logger ] The default logger.
      #
      # @since 0.0.1
      def default_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      # Set the logger.
      #
      # @example Set the logger.
      #   Loggable.logger = logger
      #
      # @return [ Logger ] The logger.
      #
      # @since 0.0.1
      def logger=(logger)
        @logger = logger
      end
    end
  end
end
