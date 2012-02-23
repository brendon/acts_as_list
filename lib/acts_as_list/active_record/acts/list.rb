module ActiveRecord
  module Acts #:nodoc:
    module List #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      # This +acts_as+ extension provides the capabilities for sorting and reordering a number of objects in a list.
      # The class that has this specified needs to have a +position+ column defined as an integer on
      # the mapped database table.
      #
      # Todo list example:
      #
      #   class TodoList < ActiveRecord::Base
      #     has_many :todo_items, :order => "position"
      #   end
      #
      #   class TodoItem < ActiveRecord::Base
      #     belongs_to :todo_list
      #     acts_as_list :scope => :todo_list
      #   end
      #
      #   todo_list.first.move_to_bottom
      #   todo_list.last.move_higher
      module ClassMethods
        # Configuration options are:
        #
        # * +column+ - specifies the column name to use for keeping the position integer (default: +position+)
        # * +scope+ - restricts what is to be considered a list. Given a symbol, it'll attach <tt>_id</tt> 
        #   (if it hasn't already been added) and use that as the foreign key restriction. It's also possible 
        #   to give it an entire string that is interpolated if you need a tighter scope than just a foreign key.
        #   Example: <tt>acts_as_list :scope => 'todo_list_id = #{todo_list_id} AND completed = 0'</tt>
        # * +top_of_list+ - defines the integer used for the top of the list. Defaults to 1. Use 0 to make the collection
        #   act more like an array in its indexing.
        def acts_as_list(options = {})
          configuration = { :column => "position", :scope => "1 = 1", :top_of_list => 1}
          configuration.update(options) if options.is_a?(Hash)

          configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/

          if configuration[:scope].is_a?(Symbol)
            scope_condition_method = %(
              def scope_condition
                self.class.send(:sanitize_sql_hash_for_conditions, { :#{configuration[:scope].to_s} => send(:#{configuration[:scope].to_s}) })
              end
            )
          elsif configuration[:scope].is_a?(Array)
            scope_condition_method = %(
              def scope_condition
                attrs = %w(#{configuration[:scope].join(" ")}).inject({}) do |memo,column| 
                  memo[column.intern] = send(column.intern); memo
                end
                self.class.send(:sanitize_sql_hash_for_conditions, attrs)
              end
            )
          else
            scope_condition_method = "def scope_condition() \"#{configuration[:scope]}\" end"
          end

          class_eval <<-EOV
            include ActiveRecord::Acts::List::InstanceMethods

            def acts_as_list_top
              #{configuration[:top_of_list]}.to_i
            end

            def acts_as_list_class
              ::#{self.name}
            end

            def position_column
              '#{configuration[:column]}'
            end

            #{scope_condition_method}

            after_destroy :decrement_positions_on_lower_items
            before_validation :add_to_list_bottom, :on => :create
          EOV
        end
      end

      # All the methods available to a record that has had <tt>acts_as_list</tt> specified. Each method works
      # by assuming the object to be the item in the list, so <tt>chapter.move_lower</tt> would move that chapter
      # lower in the list of all chapters. Likewise, <tt>chapter.first?</tt> would return +true+ if that chapter is
      # the first in the list of all chapters.
      module InstanceMethods
        # Insert the item at the given position (defaults to the top position of 1).
        def insert_at(position = acts_as_list_top)
          insert_at_position(position)
        end

        # Swap positions with the next lower item, if one exists.
        def move_lower
          return unless lower_item

          acts_as_list_class.transaction do
            lower_item.decrement_position
            increment_position
          end
        end

        # Swap positions with the next higher item, if one exists.
        def move_higher
          return unless higher_item

          acts_as_list_class.transaction do
            higher_item.increment_position
            decrement_position
          end
        end

        # Move to the bottom of the list. If the item is already in the list, the items below it have their
        # position adjusted accordingly.
        def move_to_bottom
          return unless in_list?
          acts_as_list_class.transaction do
            decrement_positions_on_lower_items
            assume_bottom_position
          end
        end

        # Move to the top of the list. If the item is already in the list, the items above it have their
        # position adjusted accordingly.
        def move_to_top
          return unless in_list?
          acts_as_list_class.transaction do
            increment_positions_on_higher_items
            assume_top_position
          end
        end

        # Removes the item from the list.
        def remove_from_list
          if in_list?
            decrement_positions_on_lower_items
            update_attribute position_column, nil
          end
        end

        # Increase the position of this item without adjusting the rest of the list.
        def increment_position
          return unless in_list?
          update_attribute position_column, self.send(position_column).to_i + 1
        end

        # Decrease the position of this item without adjusting the rest of the list.
        def decrement_position
          return unless in_list?
          update_attribute position_column, self.send(position_column).to_i - 1
        end

        # Return +true+ if this object is the first in the list.
        def first?
          return false unless in_list?
          self.send(position_column) == acts_as_list_top
        end

        # Return +true+ if this object is the last in the list.
        def last?
          return false unless in_list?
          self.send(position_column) == bottom_position_in_list
        end

        # Return the next higher item in the list.
        def higher_item
          return nil unless in_list?
          acts_as_list_class.find(:first, :conditions =>
            "#{scope_condition} AND #{position_column} = #{(send(position_column).to_i - 1).to_s}"
          )
        end

        # Return the next lower item in the list.
        def lower_item
          return nil unless in_list?
          acts_as_list_class.find(:first, :conditions =>
            "#{scope_condition} AND #{position_column} = #{(send(position_column).to_i + 1).to_s}"
          )
        end

        # Test if this record is in a list
        def in_list?
          !not_in_list?
        end
        
        def not_in_list?
          send(position_column).nil?
        end
        
        def default_position
          acts_as_list_class.columns_hash[position_column.to_s].default
        end

        def default_position?
          default_position == send(position_column)
        end

        private
          def add_to_list_top
            increment_positions_on_all_items
          end

          def add_to_list_bottom
            if not_in_list? || default_position?
              self[position_column] = bottom_position_in_list.to_i + 1
            else
              increment_positions_on_lower_items(self[position_column])
            end
          end

          # Overwrite this method to define the scope of the list changes
          def scope_condition() "1" end

          # Returns the bottom position number in the list.
          #   bottom_position_in_list    # => 2
          def bottom_position_in_list(except = nil)
            item = bottom_item(except)
            item ? item.send(position_column) : acts_as_list_top - 1
          end

          # Returns the bottom item
          def bottom_item(except = nil)
            conditions = scope_condition
            conditions = "#{conditions} AND #{self.class.primary_key} != #{except.id}" if except
            acts_as_list_class.unscoped.find(:first, :conditions => conditions, :order => "#{position_column} DESC")
          end

          # Forces item to assume the bottom position in the list.
          def assume_bottom_position
            update_attribute(position_column, bottom_position_in_list(self).to_i + 1)
          end

          # Forces item to assume the top position in the list.
          def assume_top_position
            update_attribute(position_column, acts_as_list_top)
          end

          # This has the effect of moving all the higher items up one.
          def decrement_positions_on_higher_items(position)
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} - 1)", "#{scope_condition} AND #{position_column} <= #{position}"
            )
          end

          # This has the effect of moving all the lower items up one.
          def decrement_positions_on_lower_items(position=nil)
            return unless in_list?
            position ||= send(position_column).to_i
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} - 1)", "#{scope_condition} AND #{position_column} > #{position}"
            )
          end

          # This has the effect of moving all the higher items down one.
          def increment_positions_on_higher_items
            return unless in_list?
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} + 1)", "#{scope_condition} AND #{position_column} < #{send(position_column).to_i}"
            )
          end

          # This has the effect of moving all the lower items down one.
          def increment_positions_on_lower_items(position)
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} + 1)", "#{scope_condition} AND #{position_column} >= #{position}"
           )
          end

          # Increments position (<tt>position_column</tt>) of all items in the list.
          def increment_positions_on_all_items
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} + 1)",  "#{scope_condition}"
            )
          end

          # Reorders intermediate items to support moving an item from old_position to new_position.
          def shuffle_positions_on_intermediate_items(old_position, new_position)
            return if old_position == new_position

            if old_position < new_position
              # Decrement position of intermediate items
              #
              # e.g., if moving an item from 2 to 5,
              # move [3, 4, 5] to [2, 3, 4]
              acts_as_list_class.update_all(
                "#{position_column} = (#{position_column} - 1)", "#{scope_condition} AND #{position_column} > #{old_position} AND #{position_column} <= #{new_position}"
              )
            else
              # Increment position of intermediate items
              #
              # e.g., if moving an item from 5 to 2,
              # move [2, 3, 4] to [3, 4, 5]
              acts_as_list_class.update_all(
                "#{position_column} = (#{position_column} + 1)", "#{scope_condition} AND #{position_column} >= #{new_position} AND #{position_column} < #{old_position}"
              )
            end
          end

          def insert_at_position(position)
            if in_list?
              old_position = send(position_column).to_i
              return if position == old_position
              shuffle_positions_on_intermediate_items(old_position, position)
            else
              increment_positions_on_lower_items(position)
            end
            self.update_attribute(position_column, position)
          end

          # used by insert_at_position instead of remove_from_list, as postgresql raises error if position_column has non-null constraint
          def store_at_0
            if in_list?
              old_position = send(position_column).to_i
              update_attribute(position_column, 0)
              decrement_positions_on_lower_items(old_position)
            end
          end
      end 
    end
  end
end
