module ActiveRecord::Acts::List::UpdatePositonDefiner #:nodoc:
  def self.call(caller_class)
    caller_class.class_eval do
      define_singleton_method :decrement_all do
        update_all_with_touch "#{quoted_position_column} = (#{quoted_position_column_with_table_name} - 1)"
      end

      define_singleton_method :increment_all do
        update_all_with_touch "#{quoted_position_column} = (#{quoted_position_column_with_table_name} + 1)"
      end

      define_singleton_method :update_all_with_touch do |updates|
        record = new
        attrs = record.send(:timestamp_attributes_for_update_in_model)
        now = record.send(:current_time_from_proper_timezone)

        query = attrs.map { |attr| "#{connection.quote_column_name(attr)} = :now" }
        query.push updates
        query = query.join(", ")

        update_all([query, now: now])
      end
    end
  end
end
