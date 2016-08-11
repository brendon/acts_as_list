source "http://rubygems.org"

gem "sqlite3", platforms: [:ruby]
gem "activerecord-jdbcsqlite3-adapter", platforms: [:jruby]

platforms :rbx do
  gem "rubysl", "~> 2.0"
  gem "rubinius-developer_tools"
  gem "rubysl-test-unit"
end

gem "rack", "~> 1", platforms: [:ruby_19, :ruby_20, :ruby_21, :jruby]

gemspec

gem "rake"
gem "appraisal"
gem "github_changelog_generator", "1.9.0"

group :test do
	gem "minitest", "~> 5.0"
  gem "test_after_commit", "~> 0.4.2"
end
