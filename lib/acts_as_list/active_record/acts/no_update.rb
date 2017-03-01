module ActiveRecord
  module Acts
    module List
      module NoUpdate
        extend ActiveSupport::Concern

        class ArrayTypeError < SyntaxError
          def initialize
            super("The first argument must be an array")
          end
        end

        class DisparityClassesError < NotImplementedError
          def initialize
            super("The first argument should contain ActiveRecord or ApplicationRecord classes")
          end
        end

        module ClassMethods
          # Lets you selectively disable all act_as_list database updates
          # for the duration of a block.
          #
          # ==== Examples
          #
          # class TodoList < ActiveRecord::Base
          #   has_many :todo_items, -> { order(position: :asc) }
          # end
          #
          # class TodoItem < ActiveRecord::Base
          #   belongs_to :todo_list
          #
          #   acts_as_list scope: :todo_list
          # end
          #
          # TodoItem.acts_as_list_no_update do
          #   TodoList.first.update(position: 2)
          # end
          #
          # Also you can pass an argument as array of extracted calsses
          # to disable from database updates.
          # It might be any class that is able to acts as list.
          #
          # ==== Examples
          #
          # class TodoList < ActiveRecord::Base
          #   has_many :todo_items, -> { order(position: :asc) }
          # end
          #
          # class TodoItem < ActiveRecord::Base
          #   belongs_to :todo_list
          #   has_many :todo_attachments, -> { order(position: :asc) }
          #
          #   acts_as_list scope: :todo_list
          # end
          #
          # class TodoAttachment < ActiveRecord::Base
          #   belongs_to :todo_list
          #   acts_as_list scope: :todo_item
          # end
          #
          # TodoItem.acts_as_list_no_update([TodoAttachment]) do
          #   TodoItem.find(10).update(position: 2)
          #   TodoAttachment.find(10).update(position: 1)
          #   TodoAttachment.find(11).update(position: 2)
          # end

          def acts_as_list_no_update(extra_klasses = [], &block)
            return raise ArrayTypeError unless extra_klasses.is_a?(Array)

            extra_klasses << self

            return raise DisparityClassesError unless active_record_objects?(extra_klasses)

            NoUpdate.apply_to(extra_klasses, &block)
          end

          private

          def active_record_objects?(extra_klasses)
            extra_klasses.all? { |klass| klass.ancestors.include? ActiveRecord::Base }
          end
        end

        class << self
          def apply_to(klasses)
            extracted_klasses.push(*klasses)
            yield
          ensure
            extracted_klasses.clear
          end

          def applied_to?(klass)
            extracted_klasses.any? { |k| k == klass }
          end

          private

            def extracted_klasses
              Thread.current[:act_as_list_no_update] ||= []
            end
        end

        def act_as_list_no_update?
          NoUpdate.applied_to?(self.class)
        end
      end
    end
  end
end
