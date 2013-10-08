# encoding: utf-8
require 'bones/rpc/connection'
require 'monitor'

module Bones
  module RPC
    module Synchronous

      # This class contains behaviour of Bones::RPC socket connections.
      #
      # @since 0.0.1
      class Connection < ::Bones::RPC::Connection

        require 'bones/rpc/synchronous/connection/reader'
        require 'bones/rpc/synchronous/connection/socket'
        require 'bones/rpc/synchronous/connection/writer'

        writer_class ::Bones::RPC::Synchronous::Connection::Writer

        def write(operations)
          with_connection do |socket|
            proxy = writer.write(operations)
            if proxy
              Timeout::timeout(timeout) do
                while not proxy.registry_empty?
                  writer.reader.read(proxy)
                end
              end
            end
          end
        end

      end
    end
  end
end
