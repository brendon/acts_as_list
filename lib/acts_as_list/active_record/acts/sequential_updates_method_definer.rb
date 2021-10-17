# frozen_string_literal: true

module ActiveRecord::Acts::List::SequentialUpdatesMethodDefiner #:nodoc:
  def self.call(caller_class, column, sequential_updates_option)
    caller_class.class_eval do
      unless defined?(@@sequential_updates)
        if sequential_updates_option.nil?
          table_exists =
            if active_record_version_is?('>= 5')
              caller_class.connection.data_source_exists?(caller_class.table_name)
            else
              caller_class.connection.table_exists?(caller_class.table_name)
            end
          index_exists = caller_class.connection.index_exists?(caller_class.table_name, column, unique: true)
          @@sequential_updates = table_exists && index_exists
        else
          @@sequential_updates = sequential_updates_option
        end
      end

      define_method :sequential_updates? do
        @@sequential_updates
      end

      private :sequential_updates?
    end
  end
end
