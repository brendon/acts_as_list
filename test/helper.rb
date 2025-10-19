# frozen_string_literal: true

# $DEBUG = true

require "rubygems"
require "bundler/setup"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'logger'
require "active_record"
require "minitest/autorun"
require "mocha/minitest"
require "#{File.dirname(__FILE__)}/../init"

ENV["DB"] = "mysql" unless ENV["DB"]

if defined?(ActiveRecord::VERSION) &&
  ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 2

  # Was removed in Rails 5 and is effectively true.
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end

database_configuration = ENV["CI"] ? "test/support/ci_database.yml" : "test/support/database.yml"

ActiveRecord::Base.configurations = YAML.safe_load(IO.read(database_configuration))
ActiveRecord::Base.establish_connection(ENV["DB"].to_sym)
ActiveRecord::Schema.verbose = false

def teardown_db
  if ActiveRecord::VERSION::MAJOR >= 5
    tables = ActiveRecord::Base.lease_connection.data_sources
  else
    tables = ActiveRecord::Base.lease_connection.tables
  end

  tables.each do |table|
    ActiveRecord::Base.lease_connection.drop_table(table)
  end
end

require "shared"

# ActiveRecord::Base.logger = Logger.new(STDOUT)

def assert_equal_or_nil(a, b)
  if a.nil?
    assert_nil b
  else
    assert_equal a, b
  end
end

def assert_no_deprecation_warning_raised_by(failure_message = 'ActiveRecord deprecation warning raised when we didn\'t expect it', pass_message = 'No ActiveRecord deprecation raised')
  original_behavior = active_record_deprecator.behavior
  active_record_deprecator.behavior = :raise
  begin
    yield
  rescue ActiveSupport::DeprecationException => e
    flunk "#{failure_message}: #{e}"
  rescue
    raise
  else
    pass pass_message
  end
ensure
  active_record_deprecator.behavior = original_behavior
end

def active_record_deprecator
  if ActiveRecord::VERSION::MAJOR == 7 && ActiveRecord::VERSION::MINOR >= 1 || ActiveRecord::VERSION::MAJOR > 7
    ActiveRecord.deprecator
  else
    ActiveSupport::Deprecation
  end
end
