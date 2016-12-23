module ActiveRecord::Acts::List::ColumnMethodDefiner #:nodoc:
  def self.call(caller_class, column)
    caller_class.class_eval do
      attr_reader :position_changed

      define_method :position_column do
        column
      end

      define_method :"#{column}=" do |position|
        write_attribute(column, position)
        @position_changed = true
      end

      # only add to attr_accessible
      # if the class has some mass_assignment_protection
      if defined?(accessible_attributes) and !accessible_attributes.blank?
        attr_accessible :"#{column}"
      end

      define_singleton_method :quoted_position_column do
        @_quoted_position_column ||= connection.quote_column_name(column)
      end

      define_singleton_method :quoted_position_column_with_table_name do
        @_quoted_position_column_with_table_name ||= "#{caller_class.quoted_table_name}.#{quoted_position_column}"
      end

      define_singleton_method :decrement_all do
        update_all_with_touch "#{quoted_position_column} = (#{quoted_position_column_with_table_name} - 1)"
      end

      define_singleton_method :increment_all do
        update_all_with_touch_unique_workaround "#{quoted_position_column} = (#{quoted_position_column_with_table_name} + 1)"
      end

      define_singleton_method :update_all_with_touch do |updates|
        record = new
        attrs = record.send(:timestamp_attributes_for_update_in_model)
        now = record.send(:current_time_from_proper_timezone)

        attrs.each do |attr|
          updates << ", #{connection.quote_column_name(attr)} = #{connection.quote(connection.quoted_date(now))}"
        end

        update_all(updates)
      end

      define_singleton_method :update_all_with_touch_unique_workaround do |updates|
        if connection.index_exists?(caller_class.table_name, column, unique: true)
          # unique constraint prevents regular increment_all, so we use work-around with negative values
          # http://stackoverflow.com/questions/7703196/sqlite-increment-unique-integer-field
          # it's not specific to SQLite only, PostgreSQL has same issue
          update_all_with_touch "#{quoted_position_column} = -#{quoted_position_column_with_table_name}"
          update_all_with_touch updates.sub('= (', '= (-')
        else
          update_all_with_touch updates
        end
      end
    end
  end
end
