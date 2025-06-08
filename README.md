# Ragged

[![CI](https://github.com/antarr/ragged/actions/workflows/ci.yml/badge.svg)](https://github.com/antarr/ragged/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/antarr/ragged/branch/main/graph/badge.svg)](https://codecov.io/gh/antarr/ragged)
[![Ruby](https://img.shields.io/badge/ruby-3.2+-red.svg)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-8.0.2-red.svg)](https://rubyonrails.org)

A modern Rails 8 application with a beautiful coming soon landing page and comprehensive error pages.

## Features

- 🎨 **Beautiful Coming Soon Page** - Modern gradient design with animated elements
- 🚨 **Custom Error Pages** - Consistent design across all error states (404, 422, 500, 400, 406)
- ✅ **Comprehensive Test Suite** - RSpec tests with SimpleCov coverage reporting
- 🔐 **User Authentication** - Secure authentication system with BCrypt
- 📱 **Responsive Design** - Tailwind CSS with mobile-first approach
- ⚡ **Modern Rails Stack** - Rails 8 with Hotwire, Stimulus, and Import Maps

## Tech Stack

- **Ruby** 3.2+
- **Rails** 8.0.2
- **Database** SQLite3 with Solid adapters
- **Frontend** Hotwire (Turbo + Stimulus) with Tailwind CSS
- **Testing** RSpec with SimpleCov
- **CI/CD** GitHub Actions with Codecov integration

## Getting Started

### Prerequisites

- Ruby 3.2 or higher
- Rails 8.0.2
- SQLite3

### Installation

1. Clone the repository
```bash
git clone https://github.com/antarr/ragged.git
cd ragged
```

2. Install dependencies
```bash
bundle install
```

3. Set up the database
```bash
bin/rails db:prepare
```

4. Start the development server
```bash
bin/dev
```

Visit http://localhost:3000 to see the application.

## Development

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run tests with coverage
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb
```

### Code Quality

```bash
# Run linter
bin/rubocop

# Run security checks
bin/brakeman

# Auto-fix linting issues
bin/rubocop -A
```

### Database Commands

```bash
# Create and migrate database
bin/rails db:create db:migrate

# Reset database
bin/rails db:reset

# Load seed data
bin/rails db:seed
```

## Deployment

This application is configured for deployment with:

- **Kamal** - For containerized deployment
- **Docker** - Container support included
- **GitHub Actions** - Automated CI/CD pipeline

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
