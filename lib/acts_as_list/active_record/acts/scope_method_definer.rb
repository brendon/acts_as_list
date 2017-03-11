module ActiveRecord::Acts::List::ScopeMethodDefiner #:nodoc:
  extend ActiveSupport::Inflector

  def self.call(caller_class, scope)
    scope = idify(scope) if scope.is_a?(Symbol)

    caller_class.class_eval do
      define_method :scope_name do
        scope
      end

      if scope.is_a?(Symbol)
        define_method :scope_condition do
          { scope => send(:"#{scope}") }
        end

        define_method :scope_changed? do
          changed.include?(scope_name.to_s)
        end

        define_method :destroyed_via_scope? do
          return false if ActiveRecord::VERSION::MAJOR < 4
          scope == (destroyed_by_association && destroyed_by_association.foreign_key.to_sym)
        end
      elsif scope.is_a?(Array)
        define_method :scope_condition do
          scope.inject({}) do |hash, column|
            hash.merge!({ column.to_sym => read_attribute(column.to_sym) })
          end
        end

        define_method :scope_changed? do
          (scope_condition.keys & changed.map(&:to_sym)).any?
        end

        define_method :destroyed_via_scope? do
          return false if ActiveRecord::VERSION::MAJOR < 4
          scope_condition.keys.include? (destroyed_by_association && destroyed_by_association.foreign_key.to_sym)
        end
      else
        define_method :scope_condition do
          eval "%{#{scope}}"
        end

        define_method :scope_changed? do
          false
        end

        define_method :destroyed_via_scope? do
          false
        end
      end

      self.scope :in_list, lambda { where("#{quoted_position_column_with_table_name} IS NOT NULL") }
    end
  end

  def self.idify(name)
    return name if name.to_s =~ /_id$/

    foreign_key(name).to_sym
  end
end
