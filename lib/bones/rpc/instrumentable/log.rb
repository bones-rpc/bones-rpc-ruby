# encoding: utf-8
module Bones
  module RPC
    module Instrumentable

      # Provides logging instrumentation for compatibility with active support
      # notifications.
      #
      # @since 0.0.1
      class Log

        class << self

          # Instrument the log payload.
          #
          # @example Instrument the log payload.
          #   Log.instrument("bones-rpc.ops", {})
          #
          # @param [ String ] name The name of the logging type.
          # @param [ Hash ] payload The log payload.
          #
          # @return [ Object ] The result of the yield.
          #
          # @since 0.0.1
          def instrument(name, payload = {})
            started = Time.new
            begin
              yield if block_given?
            rescue Exception => e
              payload[:exception] = [ e.class.name, e.message ]
              raise e
            ensure
              runtime = ("%.4fms" % (1000 * (Time.now.to_f - started.to_f)))
              if name == TOPIC
                Bones::RPC::Loggable.log_operations(payload[:prefix], payload[:ops], runtime)
              else
                Bones::RPC::Loggable.debug(payload[:prefix], payload.reject { |k,v| k == :prefix }, runtime)
              end
            end
          end
        end
      end
    end
  end
end
