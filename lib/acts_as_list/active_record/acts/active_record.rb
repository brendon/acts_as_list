ActiveSupport.on_load :active_record do
  extend ActiveRecord::Acts::List::ClassMethods
end
