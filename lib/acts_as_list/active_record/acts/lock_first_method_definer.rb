# frozen_string_literal: true

module ActiveRecord::Acts::List::LockFirstMethodDefiner #:nodoc:
  def self.call(caller_class, lock_first)
    caller_class.class_eval do
      define_method :lock_first? do
        lock_first
      end
    end
  end
end
