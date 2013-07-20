# encoding: utf-8
module Bones
  module RPC
    class Future < ::Celluloid::Future

      def initialize(*args, &block)
        @start = Time.now
        super
      end

      def signal(*args, &block)
        @stop = Time.now
        super
      end

      def runtime
        if @stop
          @stop - @start
        else
          Time.now - @start
        end
      end

    end
  end
end
