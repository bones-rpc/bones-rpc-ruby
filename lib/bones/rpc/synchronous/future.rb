# encoding: utf-8
require 'thread'

module Bones
  module RPC
    module Synchronous
      class Future

        def initialize
          @start = Time.now
          @mutex = Mutex.new
          @ready = false
          @result = nil
          @forwards = nil
        end

        # Check if this future has a value yet
        def ready?
          @ready
        end

        # Obtain the value for this Future
        def value(timeout = nil)
          ready = result = nil

          begin
            @mutex.lock

            if @ready
              ready = true
              result = @result
            end
          ensure
            @mutex.unlock
          end

          unless ready
            if timeout
              raise TimeoutError, "Timeout not supported by Bones::RPC::Synchronous backend"
            end
          end

          if result
            result.value
          else
            raise TimeoutError, "Timeout not supported by Bones::RPC::Synchronous backend"
          end
        end
        alias_method :call, :value

        # Signal this future with the given result value
        def signal(value)
          @stop = Time.now
          result = Result.new(value, self)

          @mutex.synchronize do
            raise "the future has already happened!" if @ready

            @result = result
            @ready = true
          end
        end
        alias_method :<<, :signal

        # Inspect this Bones::RPC::Synchronous::Future
        alias_method :inspect, :to_s

        def runtime
          if @stop
            @stop - @start
          else
            Time.now - @start
          end
        end

        # Wrapper for result values to distinguish them in mailboxes
        class Result
          attr_reader :future

          def initialize(result, future)
            @result, @future = result, future
          end

          def value
            @result.value
          end
        end
      end
    end
  end
end
