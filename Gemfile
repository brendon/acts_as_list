# frozen_string_literal: true

source "https://rubygems.org"

# Runtime dependencies are specified in acts_as_list.gemspec
gemspec

# Set RAILS_VERSION to test against the latest release in a Rails series (e.g. RAILS_VERSION=7.2).
# When unset, the newest Rails supported by the running Ruby is used.
rails_version = ENV["RAILS_VERSION"]

if rails_version
  gem "activerecord", "~> #{rails_version}.0"
  gem "activesupport", "~> #{rails_version}.0"
end

gem "rake", "~> 13.0"

gem "minitest", "~> 5.0"
gem "minitest-hooks", "~> 1.5.1"
gem "mocha", "~> 2.1.0"
gem "timecop", "~> 0.9.8"

gem "mysql2", "0.5.6"
gem "pg", "~> 1.5.5"

if rails_version.nil? || Gem::Version.new(rails_version) >= Gem::Version.new("7.2")
  gem "sqlite3", "~> 2.7.3"
else
  gem "sqlite3", "~> 1.7.3"
end

# Standard library gems that Rails relies on but older Rails releases do not declare.
gem "base64"     # Removed from default gems in Ruby 3.4
gem "benchmark"  # Removed from default gems in Ruby 3.5
gem "bigdecimal" # Removed from default gems in Ruby 3.4
gem "logger"     # Removed from default gems in Ruby 3.5
gem "mutex_m"    # Removed from default gems in Ruby 3.4
