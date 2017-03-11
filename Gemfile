source "http://rubygems.org"

gem "rack", "~> 1", platforms: [:ruby_19, :ruby_20, :ruby_21, :jruby]

gemspec

gem "rake"
gem "appraisal"
gem "github_changelog_generator", "1.9.0"

group :test do
  gem "minitest", "~> 5.0"
  gem "test_after_commit", "~> 0.4.2"
  gem "timecop"
  gem "mocha"
end

group :sqlite do
  gem "sqlite3", platforms: [:ruby]
  gem "activerecord-jdbcsqlite3-adapter", platforms: [:jruby]
end

group :postgresql do
  gem "pg", "~> 0.18.0", platforms: [:ruby]
  gem "activerecord-jdbcpostgresql-adapter", platforms: [:jruby]
end

group :mysql do
  gem "mysql2", "~> 0.3.10", platforms: [:ruby]
  gem "activerecord-jdbcmysql-adapter", platforms: [:jruby]
end
