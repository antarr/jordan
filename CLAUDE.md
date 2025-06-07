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

## Key Patterns

1. **No Test Framework**: Tests are not configured. If adding tests, you'll need to set up RSpec or Minitest first.

2. **Database-Backed Infrastructure**: Uses SQLite for application data and infrastructure (cache, jobs, WebSockets) via Solid adapters.

3. **Frontend Architecture**: 
   - Stimulus controllers in `app/javascript/controllers/`
   - Tailwind CSS for styling (configured in `config/tailwind.config.js`)
   - Turbo for SPA-like navigation without writing JavaScript

4. **Deployment Ready**: Includes Dockerfile and Kamal configuration for containerized deployment.

## Important Notes

- Action Mailer and Action Mailbox are disabled (commented out in config/application.rb)
- PWA support is scaffolded but not enabled by default
- No npm/yarn required - JavaScript dependencies are managed via Import Maps