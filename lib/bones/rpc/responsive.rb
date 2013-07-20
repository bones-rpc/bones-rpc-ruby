# encoding: utf-8
module Bones
  module RPC

    module Responsive

      MUTEX = Mutex.new


      def futures(socket)
        MUTEX.synchronize do
          messages[socket.object_id] ||= {}
        end
      end

      def futures_flush(socket = nil, exception)
        MUTEX.synchronize do
          targets = socket.nil? ? messages : (messages[socket.object_id] ||= {})
          targets.each do |channel, futures|
            futures.each do |id, future|
              future.signal(FutureValue.new(exception)) rescue nil
            end
          end
          targets.clear
        end
      end

      def future_get(socket, channel, id)
        MUTEX.synchronize do
          ((messages[socket.object_id] ||= {})[channel] ||= {}).delete(id)
        end
      end

      def future_store(socket, channel, id, future)
        MUTEX.synchronize do
          ((messages[socket.object_id] ||= {})[channel] ||= {})[id] = future
        end
      end

      private

      def messages
        @messages ||= {}
      end

    end
  end
end
