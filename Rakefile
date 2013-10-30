require 'bundler'
Bundler::GemHelper.install_tasks

#require 'rake'
require 'rake/testtask'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# Run the test with 'rake' or 'rake test'
desc 'Default: run acts_as_list unit tests and specs'
task :default => :test
task :default => :spec

desc 'Test the acts_as_list plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = false
end

# Run the rdoc task to generate rdocs for this gem
require 'rdoc/task'
RDoc::Task.new do |rdoc|
  require "acts_as_list/version"
  version = ActiveRecord::Acts::List::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "acts_as_list-rails3 #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

