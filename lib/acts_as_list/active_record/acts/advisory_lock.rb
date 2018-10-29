# frozen_string_literal: true

require 'with_advisory_lock'

module ActiveRecord
  module Acts #:nodoc:
    module List #:nodoc:
      module AdvisoryLock  #:nodoc:
        def self.included(base)
          base.prepend(InstanceMethods)
        end

        def self.acts_as_list_methods
          ActiveRecord::Acts::List::InstanceMethods.public_instance_methods
        end

        def self.acts_as_list_lockable_methods
          acts_as_list_methods.grep(/^(insert_|move_|remove_|set_|(dec|inc)rement_)/)
        end

        module InstanceMethods
          AdvisoryLock.acts_as_list_lockable_methods.each do |m|
            define_method(m) do |*args|
              with_table_lock do
                super(*args)
              end
            end
          end

          def advisory_lock_name
            format('lock-%s', acts_as_list_class.to_s.downcase)
          end

          def with_table_lock
            acts_as_list_class.with_advisory_lock(advisory_lock_name) do
              yield
            end
          end
        end
      end
    end
  end
end
