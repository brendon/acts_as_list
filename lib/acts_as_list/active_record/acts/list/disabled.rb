module ActiveRecord
  module Acts #:nodoc:
    module List #:nodoc:
      module Disabled #:nodoc:
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Lets you selectively disable calls to all act_as_list related
          # callbacks during the duration of a block.
          #
          # ==== Examples
          #   ActiveRecord::Base.act_as_list_no_update do
          #     Project.update params[:project]  # update without callbacks
          #     Message.update params[:message]  # update without callbacks
          #   end
          #
          #   Project.act_as_list_no_update do
          #     Project.update params[:project]  # update without callbacks
          #     Message.update params[:message]  # update and run callbacks
          #   end
          #
          def act_as_list_no_update(&block)
            Disabled.apply_to(self, &block)
          end
        end

        class << self
          def apply_to(klass) #:nodoc:
            klasses.push(klass)
            yield
          ensure
            klasses.pop
          end

          def applied_to?(klass) #:nodoc:
            klasses.any? { |k| k >= klass }
          end

          private

          def klasses
            Thread.current[:act_as_list_no_update_classes] ||= []
          end
        end

        def act_as_list_callbacks_disabled? # :nodoc:
          Disabled.applied_to?(self.class)
        end
      end
    end
  end
end
