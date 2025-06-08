require 'simplecov'

if ENV['CI']
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/lib/'
  add_filter 'cypress_test_helpers_controller.rb'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Jobs', 'app/jobs'

  track_files 'app/**/*.rb'

  enable_coverage :branch

  # Minimum coverage thresholds
  minimum_coverage 60
  minimum_coverage_by_file 25
end

# After SimpleCov generates its report, automatically merge with JS coverage if available
at_exit do
  if ENV['ENABLE_JS_COVERAGE'] == 'true' && File.exist?('coverage-js/coverage-final.json')
    require_relative '../lib/coverage_merger'
    CoverageMerger.merge_reports
    puts 'Combined coverage report generated at coverage-merged/index.html'
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
