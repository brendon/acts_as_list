# frozen_string_literal: true

require_relative "lib/acts_as_list/version"

Gem::Specification.new do |spec|
  spec.name    = "acts_as_list"
  spec.version = ActiveRecord::Acts::List::VERSION
  spec.authors = ["Swanand Pagnis", "Brendon Muir"]
  spec.email   = ["swanand.pagnis@gmail.com", "brendon@spikeatschool.co.nz"]

  spec.summary     = "A gem adding sorting, reordering capabilities to an active_record model, allowing it to act as a list"
  spec.description = 'This "acts_as" extension provides the capabilities for sorting and reordering a number of objects in a list. The class that has this specified needs to have a "position" column defined as an integer on the mapped database table.'
  spec.homepage    = "https://github.com/brendon/acts_as_list"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.5"

  spec.metadata = {
    "source_code_uri"       => spec.homepage,
    "changelog_uri"         => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "funding_uri"           => "https://github.com/sponsors/brendon",
    "rubygems_mfa_required" => "true"
  }

  # Only ship what is needed at runtime, plus the license and documentation.
  # Globbing (rather than `git ls-files`) lets the gem be built without git.
  spec.files         = Dir.glob(%w[lib/**/*.rb CHANGELOG.md MIT-LICENSE README.md], base: __dir__)
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.1"
  spec.add_dependency "activesupport", ">= 6.1"
end
