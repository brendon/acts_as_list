# frozen_string_literal: true

module ActiveRecord::Acts::List::PositionColumnMethodDefiner #:nodoc:
  def self.call(caller_class, position_column, touch_on_update)
    define_class_methods(caller_class, position_column, touch_on_update)
    define_instance_methods(caller_class, position_column)

    if mass_assignment_protection_was_used_by_user?(caller_class)
      protect_attributes_from_mass_assignment(caller_class, position_column)
    end
  end

  private

  def self.define_class_methods(caller_class, position_column, touch_on_update)
    caller_class.class_eval do
      define_singleton_method :quoted_position_column do
        @_quoted_position_column ||= connection.quote_column_name(position_column)
      end

      define_singleton_method :quoted_position_column_with_table_name do
        @_quoted_position_column_with_table_name ||= "#{caller_class.quoted_table_name}.#{quoted_position_column}"
      end

      define_singleton_method :decrement_sequentially do
        pluck(primary_key).each do |id|
          where(primary_key => id).decrement_all
        end
      end

      define_singleton_method :increment_sequentially do
        pluck(primary_key).each do |id|
          where(primary_key => id).increment_all
        end
      end

      define_singleton_method :decrement_all do
        min = minimum(position_column)
        # Avoid going past top of list
        shuffle_to(min - 1) if min && min > acts_as_list_top
      end

      define_singleton_method :increment_all do
        min = minimum(position_column)
        shuffle_to(min + 1) if min
      end

      define_singleton_method :update_all_with_touch do |updates|
        updates += touch_record_sql if touch_on_update
        update_all(updates)
      end

      private

      # Update recordset to start at the given position
      define_singleton_method :shuffle_to do |position|
        max = nil
        if ActiveRecord::VERSION::MAJOR < 4
          unscoped do
            max = maximum(position_column)
          end
        else
          max = unscope(:where).maximum(position_column)
        end
        return unless max # If no records have a position we don't have to do anything.

        swap_position = max + 2 # Move recordset after the last record
        update_all_with_touch(
          "#{quoted_position_column} = #{quoted_position_column_with_table_name} + #{swap_position}"
        )

        return_from = if ActiveRecord::VERSION::MAJOR < 4
          unscoped do
            where("#{quoted_position_column_with_table_name} >= #{swap_position}").minimum(position_column)
          end
        else
          unscope(:where).where("#{quoted_position_column_with_table_name} >= #{swap_position}").minimum(position_column)
        end

        return_position = return_from - position
        # Can't specify _with_table_name as it's an UPDATE

        # unscoped is safe in this case because we're moved the
        # records we're targeting above the previous maximum position
        target_records = unscoped.where("#{quoted_position_column} >= #{swap_position}")

        case connection.class.to_s
        when "ActiveRecord::ConnectionAdapters::SQLite3Adapter"
          # Does not fill in 'holes' (if any exist) as sqlite lacks partitioning and variables.
          target_records.update_all(
          "#{quoted_position_column} = #{quoted_position_column} - #{return_position}",
        )
        when "ActiveRecord::ConnectionAdapters::Mysql2Adapter"
          ActiveRecord::Base.connection.execute("SET @position=#{position - 1};")
          target_records.order(Arel.sql quoted_position_column).update_all <<-SQL
            #{quoted_position_column} = @position := @position + 1
          SQL
        when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
          target_records.where("acts_as_list_sorted.#{primary_key} = #{quoted_table_name}.#{primary_key}").update_all <<-SQL
            #{quoted_position_column} = acts_as_list_sorted.seqnum + #{position-1}
            from (
              select acts_as_list_subselect.#{primary_key}, row_number() over (
                order by #{quoted_position_column} asc
              ) as seqnum
              from #{quoted_table_name} acts_as_list_subselect
              where #{quoted_position_column} >= #{swap_position}
            ) as acts_as_list_sorted
          SQL
        else
          raise "Unknown driver #{connection.class}"
        end
      end

      define_singleton_method :touch_record_sql do
        new.touch_record_sql
      end
    end
  end

  def self.define_instance_methods(caller_class, position_column)
    caller_class.class_eval do
      attr_reader :position_changed

      define_method :position_column do
        position_column
      end

      define_method :"#{position_column}=" do |position|
        write_attribute(position_column, position)
        @position_changed = true
      end

      define_method :touch_record_sql do
        cached_quoted_now = quoted_current_time_from_proper_timezone

        timestamp_attributes_for_update_in_model.map do |attr|
          ", #{connection.quote_column_name(attr)} = #{cached_quoted_now}"
        end.join
      end

      private

      delegate :connection, to: self

      def quoted_current_time_from_proper_timezone
        connection.quote(connection.quoted_date(
          current_time_from_proper_timezone))
      end
    end
  end

  def self.mass_assignment_protection_was_used_by_user?(caller_class)
    caller_class.class_eval do
      respond_to?(:accessible_attributes) and accessible_attributes.present?
    end
  end

  def self.protect_attributes_from_mass_assignment(caller_class, position_column)
    caller_class.class_eval do
      attr_accessible position_column.to_sym
    end
  end
end
