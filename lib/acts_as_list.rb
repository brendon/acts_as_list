require "acts_as_list/active_record/acts/column_method_definer"
require "acts_as_list/active_record/acts/scope_method_definer"
require "acts_as_list/active_record/acts/top_of_list_method_definer"
require "acts_as_list/active_record/acts/add_new_at_method_definer"
require "acts_as_list/active_record/acts/aux_method_definer"
require "acts_as_list/active_record/acts/callback_definer"
require 'acts_as_list/active_record/acts/list'

# BENJ this seems to be mine
# require "acts_as_list/active_record/acts/list/disabled"
#
# module ActsAsList
#   if defined?(Rails::Railtie)
#     class Railtie < Rails::Railtie
#       initializer 'acts_as_list.insert_into_active_record' do
#         ActiveSupport.on_load :active_record do
#           ActiveRecord::Base.send(:include, ActiveRecord::Acts::List)
#           ActiveRecord::Base.send(:include, ActiveRecord::Acts::List::Disabled)
#         end
#       end
#     end
#   elsif defined?(ActiveRecord)
#     ActiveRecord::Base.send(:include, ActiveRecord::Acts::List)
#     ActiveRecord::Base.send(:include, ActiveRecord::Acts::List::Disabled)
#   end
# end