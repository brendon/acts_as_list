require 'acts_as_list/active_record/acts/list'

module ActsAsList
  begin
    require 'rails'

    class Railtie < Rails::Railtie
      initializer 'acts_as_list.insert_into_active_record' do
        ActiveSupport.on_load :active_record do
          ActiveRecord::Base.send(:include, ActiveRecord::Acts::List)
        end
      end
    end
  rescue LoadError
    ActiveRecord::Base.send(:include, ActiveRecord::Acts::List) if defined?(ActiveRecord)
  end
end
