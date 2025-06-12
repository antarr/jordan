namespace :coverage do
  desc 'Run all tests and generate coverage report'
  task :all do
    puts 'Running RSpec tests (includes Capybara feature tests)...'
    system('bundle exec rspec') || exit(1)

    puts 'Coverage report available at coverage/index.html'
  end
end
