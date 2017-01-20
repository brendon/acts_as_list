module ActiveRecord
  module Acts
    module List
      module NoUpdate
        extend ActiveSupport::Concern

        module ClassMethods
          # Lets you selectively disable all act_as_list database updates
          # for the duration of a block.
          #
          # ==== Examples
          #   ActiveRecord::Acts::List.acts_as_list_no_update do
          #     TodoList....
          #   end
          #
          #   TodoList.acts_as_list_no_update do
          #     TodoList....
          #   end
          #
          def acts_as_list_no_update(&block)
            NoUpdate.apply_to(self, &block)
          end
        end

        class << self
          def apply_to(klass)
            klasses.push(klass)
            yield
          ensure
            klasses.pop
          end

          def applied_to?(klass)
            klasses.any? { |k| k >= klass }
          end

          private

            def klasses
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
