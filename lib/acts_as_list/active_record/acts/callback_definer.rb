module ActiveRecord::Acts::List::CallbackDefiner #:nodoc:
  def self.call(caller_class, add_new_at)
    caller_class.class_eval do
      before_validation :check_top_position

      before_destroy :lock!
      after_destroy :decrement_positions_on_lower_items

      before_update :check_scope
      after_update :update_positions

      after_commit :clear_scope_changed

      if add_new_at.present?
        before_create "add_to_list_#{add_new_at}".to_sym
      end
    end
  end
end
