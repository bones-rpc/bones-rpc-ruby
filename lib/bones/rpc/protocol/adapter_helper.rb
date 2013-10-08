# encoding: utf-8
module Bones
  module RPC
    module Protocol

      module AdapterHelper

        # Default implementation for a message is to do nothing when receiving
        # replies.
        #
        # @example Receive replies.
        #   message.receive_replies(connection)
        #
        # @param [ Connection ] connection The connection.
        #
        # @return [ nil ] nil.
        #
        # @since 0.0.1
        def receive_replies(connection); end

        # Serializes the message and all of its fields to a new buffer or to the
        # provided buffer.
        #
        # @example Serliaze the message.
        #   message.serialize
        #
        # @param [ String ] buffer A buffer to serialize to.
        #
        # @return [ String ] The result of serliazing this message
        #
        # @since 0.0.1
        def serialize(buffer, adapter)
          Adapter.get(adapter).serialize(process, buffer)
        end

        class << self

          # Extends the including class with +ClassMethods+.
          #
          # @param [Class] subclass the inheriting class
          def included(base)
            super
            base.extend(ClassMethods)
          end
          private :included
        end

        # Provides a DSL for defining struct-like fields for building messages
        # for the Mongo Wire.
        #
        # @example
        #   class Command
        #     extend Message::ClassMethods
        #
        #     int32 :length
        #   end
        #
        #   Command.fields # => [:length]
        #   command = Command.new
        #   command.length = 12
        #   command.serialize_length("") # => "\f\x00\x00\x00"
        module ClassMethods

          def deserialize(adapter, buffer="")
            adapter = Adapter.get(adapter)
            message = adapter.deserialize(buffer)
            message.shift
            new(adapter, *message)
          end

          # @return [Array] the fields defined for this message
          def fields
            @fields ||= []
          end

          def any(name)
            attr_accessor name

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def process_#{name}
                #{name}
              end
            RUBY

            fields << name
          end

          # Declare a binary field.
          #
          # @example
          #   class Query < Message
          #     binary :collection
          #   end
          #
          # @param [String] name the name of this field
          def binary(name)
            attr_accessor name

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def process_#{name}
                #{name}
              end
            RUBY

            fields << name
          end

          def integer(name)
            attr_accessor name

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}
                @#{name} ||= 0
              end

              def process_#{name}
                #{name}
              end
            RUBY

            fields << name
          end

          def list(name)
            attr_accessor name

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}
                @#{name} ||= []
              end

              def process_#{name}
                #{name}
              end
            RUBY

            fields << name
          end

          # Declares the message class as complete, and defines its serialization
          # method from the declared fields.
          def finalize
            class_eval <<-EOS, __FILE__, __LINE__ + 1
              def process
                list = []
                #{fields.map { |f| "list << process_#{f}" }.join("\n")}
                list
              end
            EOS
          end

          private

          # This ensures that subclasses of the primary wire message classes have
          # identical fields.
          def inherited(subclass)
            super
            subclass.fields.replace(fields)
          end
        end
      end
    end
  end
end
