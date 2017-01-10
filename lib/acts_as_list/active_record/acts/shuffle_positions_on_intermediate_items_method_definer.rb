module ActiveRecord::Acts::List::ShufflePositionsOnintermediateItemsDefiner #:nodoc:
  def self.call(caller_class, sequential_updates)
    caller_class.class_eval do
      # Reorders intermediate items to support moving an item from old_position to new_position.
      # unique constraint prevents regular increment_all and forces to do increments one by one
      # http://stackoverflow.com/questions/7703196/sqlite-increment-unique-integer-field
      # both SQLite and PostgreSQL (and most probably MySQL too) has same issue
      # that's why *sequential_updates* flag is here
      define_method :shuffle_positions_on_intermediate_items do |old_position, new_position, avoid_id = nil|
        return if old_position == new_position
        scope = acts_as_list_list

        if avoid_id
          scope = scope.where("#{quoted_table_name}.#{self.class.primary_key} != ?", self.class.connection.quote(avoid_id))
        end

        if old_position < new_position
          # Decrement position of intermediate items
          #
          # e.g., if moving an item from 2 to 5,
          # move [3, 4, 5] to [2, 3, 4]
          items = scope.where(
            "#{quoted_position_column_with_table_name} > ?", old_position
          ).where(
            "#{quoted_position_column_with_table_name} <= ?", new_position
          )

          if sequential_updates
            items.order("#{quoted_position_column_with_table_name} ASC").each do |item|
              item.decrement!(position_column)
            end
          else
            items.decrement_all
          end
        else
          # Increment position of intermediate items
          #
          # e.g., if moving an item from 5 to 2,
          # move [2, 3, 4] to [3, 4, 5]
          items = scope.where(
            "#{quoted_position_column_with_table_name} >= ?", new_position
          ).where(
            "#{quoted_position_column_with_table_name} < ?", old_position
          )

          if sequential_updates
            items.order("#{quoted_position_column_with_table_name} DESC").each do |item|
              item.increment!(position_column)
            end
          else
            items.increment_all
          end
        end
      end

      private :shuffle_positions_on_intermediate_items
    end
  end
end
