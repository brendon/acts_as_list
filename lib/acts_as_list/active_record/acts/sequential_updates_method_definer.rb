module ActiveRecord::Acts::List::SequentialUpdatesDefiner #:nodoc:
  def self.call(caller_class, column, sequential_updates)
    caller_class.class_eval do
      @sequential_updates = nil

      define_method :sequential_updates? do
        if !sequential_updates.nil?
          sequential_updates
        elsif !@sequential_updates.nil?
          @sequential_updates
        else
          table_exists = caller_class.connection.table_exists?(caller_class.table_name)
          index_exists = caller_class.connection.index_exists?(caller_class.table_name, column, unique: true)
          @sequential_updates = table_exists && index_exists
        end
      end

      private :sequential_updates?
    end
  end
end
