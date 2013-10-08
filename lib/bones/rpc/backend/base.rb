# encoding: utf-8
module Bones
  module RPC
    module Backend
      module Base

        def backend_name
          raise NotImplementedError, "Backend #{self.name} does not implement #backend_name"
        end

        def setup
          raise NotImplementedError, "Backend #{self.name} does not implement #setup"
        end

        def connection_class
          raise NotImplementedError, "Backend #{self.name} does not implement #connection_class"
        end

        def future_class
          raise NotImplementedError, "Backend #{self.name} does not implement #future_class"
        end

        def node_class
          raise NotImplementedError, "Backend #{self.name} does not implement #node_class"
        end

      end
    end
  end
end
