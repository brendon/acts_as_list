# frozen_string_literal: true

module ActiveRecord
  module Acts
    module List
      class WithConnection
        def initialize(recipient)
          @recipient = recipient
        end

        attr_reader :recipient

        def call
          if recipient.respond_to?(:with_connection)
            recipient.with_connection do |connection|
              yield connection
            end
          else
            yield recipient.connection
          end
        end
      end
    end
  end
end
