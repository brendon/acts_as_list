module ActiveRecord::Acts::List::CallbackDefiner #:nodoc:
  def self.call(caller_class, add_new_at)
    caller_class.class_eval do
      before_validation :check_top_position, unless: :act_as_list_no_update?

      # lock! reloads the record and we lose the destroyed_by_association information
      # so set_destroyed_by_association_foreign_key must come first
      before_destroy :set_destroyed_by_association_foreign_key, :lock!
      after_destroy :decrement_positions_on_lower_items, unless: "destroyed_via_scope? || act_as_list_no_update?"

      before_update :check_scope, unless: :act_as_list_no_update?
      after_update :update_positions, unless: :act_as_list_no_update?

      after_commit :clear_scope_changed

      if add_new_at.present?
        before_create "add_to_list_#{add_new_at}".to_sym, unless: :act_as_list_no_update?
      end
    end
  end
end
