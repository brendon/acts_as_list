# frozen_string_literal: true

require_relative './with_connection'

module ActiveRecord::Acts::List::SequentialUpdatesMethodDefiner #:nodoc:
  def self.call(caller_class, column, sequential_updates_option)
    caller_class.class_eval do
      define_method :sequential_updates? do
        return @sequential_updates if defined?(@sequential_updates)

        return @sequential_updates = sequential_updates_option unless sequential_updates_option.nil?

        ActiveRecord::Acts::List::WithConnection.new(caller_class).call do |connection|
          table_exists =
            if active_record_version_is?('>= 5')
              connection.data_source_exists?(caller_class.table_name)
            else
              connection.table_exists?(caller_class.table_name)
            end
          index_exists = connection.index_exists?(caller_class.table_name, column, unique: true)
          @sequential_updates = table_exists && index_exists
        end
      end

      private :sequential_updates?
    end
  end
end
