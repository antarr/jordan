# Coverage Configuration

This project includes comprehensive code coverage collection for both Ruby (via SimpleCov) and JavaScript (via NYC/Istanbul with Cypress).

## Quick Start

### Run all tests with combined coverage:
```bash
bundle exec rake coverage:all
```

This will:
1. Run RSpec tests (Ruby coverage)
2. Start Rails server with JS instrumentation
3. Run Cypress tests (JavaScript coverage)
4. Generate and merge both coverage reports

### View Reports

- **Combined Coverage**: `open coverage-merged/index.html`
- **Ruby Only**: `open coverage/index.html`
- **JavaScript Only**: `open coverage-js/lcov-report/index.html`

## Individual Commands

### Ruby Coverage (RSpec)
```bash
bundle exec rspec
open coverage/index.html
```

### JavaScript Coverage (Cypress)
```bash
# Start server with JS coverage enabled
ENABLE_JS_COVERAGE=true RAILS_ENV=development bin/rails server -p 3000 -d

# Run Cypress tests
ENABLE_JS_COVERAGE=true npx cypress run --record false

# Generate JS coverage report
npx nyc report --reporter=html --reporter=lcov --report-dir=coverage-js

# Stop server
pkill -f "rails server"
```

### Merge Coverage Reports
```bash
bundle exec rake coverage:merge
```

## CI Integration

The GitHub Actions workflow automatically:
1. Runs RSpec tests with Ruby coverage
2. Runs Cypress tests with JavaScript coverage enabled
3. Generates separate coverage reports
4. Merges them into a combined report
5. Uploads all reports as artifacts

## Configuration Files

- **SimpleCov**: `spec/spec_helper.rb`
- **NYC/Istanbul**: `.nycrc.json`
- **Babel**: `babel.config.js`
- **Cypress**: `cypress.config.js` and `cypress/support/e2e.js`

## Coverage Thresholds

- **Ruby**: 70% line coverage minimum
- **JavaScript**: Collected but no enforced minimum (add to .nycrc.json if needed)

## How It Works

1. **Ruby Coverage**: SimpleCov instruments Ruby code during RSpec test execution
2. **JavaScript Coverage**: 
   - Babel + Istanbul instrument JS files when `ENABLE_JS_COVERAGE=true`
   - Cypress code coverage plugin collects coverage during E2E tests
   - NYC generates reports from collected data
3. **Merging**: Custom Ruby script combines both reports into unified view

## Troubleshooting

### JavaScript Coverage Shows 0%
- Ensure `ENABLE_JS_COVERAGE=true` is set when starting Rails server
- Check that Cypress tests are actually interacting with JavaScript
- Verify middleware is loaded (check Rails logs for JavascriptCoverageMiddleware)

### Missing Coverage Files
- Run tests first to generate coverage data
- Check that both `coverage/` and `coverage-js/` directories exist
- Ensure NYC has write permissions to create `.nyc_output/`

### Coverage Not Merging
- Verify both Ruby and JS coverage reports exist
- Check `bundle exec rake coverage:merge` output for errors
- Ensure `CoverageMerger` class can be loaded