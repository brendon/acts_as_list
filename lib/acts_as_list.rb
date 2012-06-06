require 'acts_as_list/active_record/acts/list'

module ActsAsList
  if defined? Rails::Railtie
    require 'rails'
    class Railtie < Rails::Railtie
      initializer 'acts_as_list.insert_into_active_record' do
        ActiveSupport.on_load :active_record do
          ActsAsList::Railtie.insert
        end
      end
    end
  end

  class Railtie
    def self.insert
      if defined?(ActiveRecord)
        ActiveRecord::Base.send(:include, ActiveRecord::Acts::List)
      end
    end
  end
end

ActsAsList::Railtie.insert
