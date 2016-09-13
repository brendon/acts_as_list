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
    end
  end
end
