source "http://rubygems.org"

# Specify your gem's dependencies in positioning.gemspec
gemspec

gem "rake", "~> 13.0"

gem "minitest", "~> 5.0"

if ENV["RAILS_VERSION"]
  gem "activerecord", ENV["RAILS_VERSION"]
  gem "activesupport", ENV["RAILS_VERSION"]
end
