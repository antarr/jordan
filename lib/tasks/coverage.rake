namespace :coverage do
  desc "Merge Ruby and JavaScript coverage reports"
  task :merge do
    require_relative '../coverage_merger'
    
    ruby_coverage_path = 'coverage'
    js_coverage_path = 'coverage-js'
    output_path = 'coverage-merged'
    
    CoverageMerger.merge_reports(
      ruby_coverage_path: ruby_coverage_path,
      js_coverage_path: js_coverage_path,
      output_path: output_path
    )
  end
  
  desc "Generate JavaScript coverage report from NYC data"
  task :js do
    puts "Generating JavaScript coverage report..."
    system("npx nyc report --reporter=html --reporter=lcov --reporter=json --report-dir=coverage-js")
  end
  
  desc "Run all tests and generate combined coverage report"
  task :all do
    puts "Running RSpec tests..."
    system("bundle exec rspec") || exit(1)
    
    puts "Starting Rails server for Cypress..."
    server_pid = spawn("ENABLE_JS_COVERAGE=true RAILS_ENV=development bin/rails server -p 3000 -d")
    sleep 10
    
    begin
      puts "Running Cypress tests..."
      success = system("ENABLE_JS_COVERAGE=true npx cypress run --record false")
      
      puts "Generating JavaScript coverage report..."
      system("npx nyc report --reporter=html --reporter=lcov --reporter=json --report-dir=coverage-js")
      
      puts "Merging coverage reports..."
      Rake::Task["coverage:merge"].invoke
      
      puts "Combined coverage report available at coverage-merged/index.html"
      
      exit(1) unless success
    ensure
      puts "Stopping Rails server..."
      if server_pid
        begin
          Process.kill("TERM", server_pid)
          Process.wait(server_pid, Process::WNOHANG)
        rescue Errno::ESRCH, Errno::ECHILD
          # Process already terminated
        end
      end
    end
  end
end