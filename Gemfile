source "http://rubygems.org"

gemspec

gem "rake"
gem "appraisal"

group :development do
  gem "github_changelog_generator", "1.9.0"
end

group :test do
  gem "minitest", "~> 5.0"
  gem "test_after_commit", "~> 0.4.2"
  gem "timecop"
  gem "mocha"
end

group :sqlite do
  gem "sqlite3", platforms: [:ruby]
end

group :postgresql do
  gem "pg", "~> 0.18.0", platforms: [:ruby]
end
