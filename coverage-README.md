# Coverage Configuration

This project includes comprehensive code coverage collection for both Ruby (via SimpleCov) and JavaScript (via Capybara system tests).

## Quick Start

### Run all tests with coverage:
```bash
bundle exec rspec
```

This will:
1. Run RSpec tests (Ruby coverage)
2. Run Capybara feature tests (JavaScript coverage via browser interactions)
3. Generate coverage reports

### View Reports

- **Ruby Coverage**: `open coverage/index.html`

## Individual Commands

### Ruby Coverage (RSpec)
```bash
bundle exec rspec
open coverage/index.html
```

### Feature Tests (Capybara)
```bash
bundle exec rspec spec/features
```

## CI Integration

The GitHub Actions workflow automatically:
1. Runs RSpec tests with Ruby coverage
2. Runs Capybara feature tests for JavaScript behavior
3. Generates coverage reports
4. Uploads reports as artifacts

## Configuration Files

- **SimpleCov**: `spec/spec_helper.rb`
- **Capybara**: `spec/rails_helper.rb`

## Coverage Thresholds

- **Ruby**: 60% line coverage minimum (excludes lib/ infrastructure code)

## Coverage Scope

- **Included**: All files in `app/` directory (controllers, models, helpers, jobs, views)
- **Excluded**: `lib/`, `bin/`, `db/`, `spec/`, `test/`, `config/`, `vendor/`

## How It Works

1. **Ruby Coverage**: SimpleCov instruments Ruby code during RSpec test execution
2. **JavaScript Testing**: Capybara feature tests drive real browser interactions to test JavaScript behavior
3. **Frontend Coverage**: JavaScript functionality is tested through user interactions via Capybara

## Troubleshooting

### Coverage Not Generating
- Ensure tests run successfully with `bundle exec rspec`
- Check SimpleCov configuration in `spec/spec_helper.rb`
- Verify coverage directory has write permissions

### Feature Tests Failing
- Check that Capybara is properly configured in `spec/rails_helper.rb`
- Ensure JavaScript is enabled for system tests
- Verify browser driver is installed (Chrome/Firefox)

### Missing Coverage Files
- Run tests first to generate coverage data
- Check that `coverage/` directory exists
- Ensure SimpleCov has write permissions