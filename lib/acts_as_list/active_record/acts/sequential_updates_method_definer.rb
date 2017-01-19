module ActiveRecord::Acts::List::SequentialUpdatesDefiner #:nodoc:
  def self.call(caller_class, column, sequential_updates_option)
    caller_class.class_eval do
      @sequential_updates = nil

      define_method :sequential_updates? do
        if @sequential_updates.nil?
          if sequential_updates_option.nil?
            table_exists = caller_class.connection.table_exists?(caller_class.table_name)
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
