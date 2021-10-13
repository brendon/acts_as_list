# frozen_string_literal: true

module ActiveRecord::Acts::List::SequentialUpdatesMethodDefiner #:nodoc:
  def self.call(caller_class, column, sequential_updates_option)
    caller_class.class_eval do
      define_method :sequential_updates? do
        if !defined?(@sequential_updates)
          if sequential_updates_option.nil?
            schema_connection = caller_class.connection.respond_to?(:schema_cache) ? caller_class.connection.schema_cache : caller_class.connection
            table_exists =
              if active_record_version_is?('>= 5')
                schema_connection.data_source_exists?(caller_class.table_name)
              else
                schema_connection.table_exists?(caller_class.table_name)
              end
            index_exists = caller_class.connection.index_exists?(caller_class.table_name, column, unique: true)
            @sequential_updates = table_exists && index_exists
          else
            @sequential_updates = sequential_updates_option
          end
        else
          @sequential_updates
        end
      end

      private :sequential_updates?
    end
  end
end
