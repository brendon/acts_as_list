# frozen_string_literal: true

module ActiveRecord::Acts::List::CallbackDefiner #:nodoc:
  def self.call(caller_class, add_new_at, lock_first = false)
    caller_class.class_eval do
      if lock_first
        # Prepended: the lock must come before every read of the save or destroy, also before the reads of
        # the callbacks and validations that the model declares above acts_as_list.
        before_validation :lock_first_before_validation, prepend: true,
          if: :moves_list_rows_on_save?, unless: Proc.new { list_rows_locked? || act_as_list_no_update? }
        before_save :lock_first_before_save, prepend: true,
          if: :moves_list_rows_on_save?, unless: Proc.new { list_rows_locked? || act_as_list_no_update? }
        before_destroy :lock_list_rows, prepend: true,
          unless: Proc.new { new_record? || destroyed_via_scope? || list_rows_locked? || act_as_list_no_update? }
      end

      before_validation :check_top_position, unless: :act_as_list_no_update?

      before_destroy :reload, unless: Proc.new { new_record? || destroyed_via_scope? || act_as_list_no_update? }
      after_destroy :decrement_positions_on_lower_items, unless: Proc.new { destroyed_via_scope? || act_as_list_no_update? }

      before_update :check_scope, unless: :act_as_list_no_update?
      after_update :update_positions, unless: :act_as_list_no_update?

      after_save :clear_scope_changed

      before_create :avoid_collision, unless: :act_as_list_no_update?
    end
  end
end
