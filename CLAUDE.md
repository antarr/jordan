# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Starting the Application
- `bin/dev` - Starts Rails server and Tailwind CSS watcher using Foreman
- `bin/rails server` - Starts only the Rails server (port 3000)
- `bin/setup` - Initial setup script that installs dependencies and prepares the database

### Database Commands
- `bin/rails db:create` - Create the database
- `bin/rails db:migrate` - Run pending migrations
- `bin/rails db:prepare` - Creates database if needed and runs migrations
- `bin/rails db:seed` - Load seed data from db/seeds.rb

### Testing Commands
- `bundle exec rspec` - Run all RSpec unit tests
- `bundle exec rspec spec/models` - Run model tests only
- `bundle exec rspec spec/controllers` - Run controller tests only
- `bundle exec rspec spec/requests` - Run request specs
- `bundle exec rspec --format documentation` - Run tests with detailed output
- `npx cypress open` - Open Cypress test runner for interactive testing
- `npx cypress run` - Run Cypress tests in headless mode
- `npm run cypress:open` - Alternative command to open Cypress (if npm script configured)
- `npm run cypress:run` - Alternative command to run Cypress headless (if npm script configured)

### Code Quality
- `bin/rubocop` - Run Ruby linting with Rails Omakase style guide
- `bin/brakeman` - Run security vulnerability scanning

### Asset Management
- Tailwind CSS compilation happens automatically with `bin/dev`
- JavaScript uses Import Maps (no build step required)
- Assets are served through Propshaft

## Architecture Overview

This is a Rails 8.0.2 application using modern Rails defaults:

- **Database**: SQLite3 with Solid adapters for caching, background jobs, and WebSockets
- **Frontend**: Hotwire (Turbo + Stimulus) with Tailwind CSS
- **JavaScript**: Import Maps for module management (no Node.js build step)
- **Asset Pipeline**: Propshaft (modern, faster alternative to Sprockets)
- **Background Jobs**: Solid Queue (database-backed)
- **WebSockets**: Action Cable with Solid Cable adapter
- **Caching**: Solid Cache (database-backed)
- **Testing**: RSpec for unit/integration tests, Cypress for end-to-end frontend testing

## Key Patterns

1. **Testing Framework**: 
   - **RSpec** for Ruby unit tests, integration tests, and API specs
   - **Cypress** for end-to-end frontend testing, user flows, and JavaScript interactions
   - Test files organized in `spec/` directory with subdirectories for different test types
   - Cypress tests located in `cypress/e2e/` directory

2. **Database-Backed Infrastructure**: Uses SQLite for application data and infrastructure (cache, jobs, WebSockets) via Solid adapters.

3. **Frontend Architecture**: 
   - Stimulus controllers in `app/javascript/controllers/`
   - Tailwind CSS for styling (configured in `config/tailwind.config.js`)
   - Turbo for SPA-like navigation without writing JavaScript
   - Cypress tests can interact with Stimulus controllers and Turbo frames

4. **Deployment Ready**: Includes Dockerfile and Kamal configuration for containerized deployment.

## Testing Strategy

### RSpec (Backend Testing)
- **Models**: Test validations, associations, and business logic
- **Controllers**: Test HTTP responses and parameter handling
- **Requests**: Test full HTTP request/response cycles
- **Features**: Test user-facing functionality with Capybara (if needed)

### Cypress (Frontend Testing)
- **User Flows**: Test complete user journeys through the application
- **JavaScript Interactions**: Test Stimulus controllers and dynamic behavior
- **Turbo Navigation**: Test SPA-like navigation and frame updates
- **Form Submissions**: Test form behavior and validation feedback
- **Responsive Design**: Test mobile and desktop layouts

## Important Notes

- Action Mailer and Action Mailbox are disabled (commented out in config/application.rb)
- PWA support is scaffolded but not enabled by default
- No npm/yarn required for application dependencies - JavaScript dependencies are managed via Import Maps
- Cypress requires Node.js/npm for installation and running tests
- Test database should be separate from development database (configured in database.yml)
