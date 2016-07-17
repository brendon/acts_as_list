require "rubygems"
require "bundler/setup"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require "active_record"
require "minitest/autorun"
require "#{File.dirname(__FILE__)}/../init"

if defined?(ActiveRecord::VERSION) &&
  ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 2

  # Was removed in Rails 5 and is effectively true.
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end

require "shared"
