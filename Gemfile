source "http://rubygems.org"

gem 'base64'     # Deprecation notice in Ruby 3.3, removed from default gems in Ruby 3.4
gem 'benchmark'  # Deprecation notice in Ruby 3.4, removed from default gems in Ruby 3.5
gem 'bigdecimal' # Deprecation notice in Ruby 3.3, removed from default gems in Ruby 3.4
gem 'logger'     # Deprecation notice in Ruby 3.4, removed from default gems in Ruby 3.5
gem 'mutex_m'    # Deprecation notice in Ruby 3.3, removed from default gems in Ruby 3.4

gem "rake", "~> 13.0"

gem "minitest", "~> 5.0"
gem "minitest-hooks", "~> 1.5.1"
gem "mocha", "~> 2.1.0"
gem "timecop", "~> 0.9.8"
gem "mysql2", "~> 0.5.6"
gem "pg", "~> 1.5.5"

rails_version = Gem::Version.new(ENV["RAILS_VERSION"])

if rails_version >= Gem::Version.new('7.2')
  gem "sqlite3", "~> 2.7.3"
else
  gem "sqlite3", "~> 1.7.3"
end

if ENV["RAILS_VERSION"]
  gem "activerecord", ENV["RAILS_VERSION"]
  gem "activesupport", ENV["RAILS_VERSION"]
end

# Specify your gem's dependencies in acts_as_list.gemspec
gemspec
