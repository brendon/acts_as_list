require "active_support/lazy_load_hooks"

ActiveSupport.on_load :active_record do
  include ActiveRecord::Acts::List
end
