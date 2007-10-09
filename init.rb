$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/acts/list'
ActiveRecord::Base.send :include, ActiveRecord::Acts::List
