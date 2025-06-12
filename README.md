# Rails 8 Application Template

[![CI](https://github.com/antarr/jordan/actions/workflows/ci.yml/badge.svg)](https://github.com/antarr/jordan/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/antarr/jordan/branch/main/graph/badge.svg)](https://codecov.io/gh/antarr/jordan)
[![Ruby](https://img.shields.io/badge/ruby-3.2+-red.svg)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-8.0.2-red.svg)](https://rubyonrails.org)

A comprehensive Rails 8 application template with advanced authentication, role-based access control, and modern frontend features. Perfect for building ecommerce platforms, social media applications, enterprise software, and SaaS products.

## Features

### 🔐 Authentication & Security
- **Multi-Method Authentication** - Email, phone, and WebAuthn/FIDO2 support
- **Two-Factor Authentication (2FA)** - WebAuthn credentials for enhanced security
- **Account Lockout System** - Configurable failed login protection with auto-unlock
- **JWT API Authentication** - Token-based API access with refresh tokens
- **Password Security** - Complexity requirements and secure storage

### 🛡️ Role-Based Access Control (RBAC)
- **Granular Permissions System** - Resource-action based permissions
- **Three Default Roles** - Admin, Moderator, and User with distinct capabilities
- **Admin Panel** - Complete role and permission management interface
- **Authorization Framework** - Controller and view-level access control

### 🗺️ Location Integration
- **Geographic Data Support** - Latitude/longitude storage with spatial indexing
- **Location Privacy Controls** - Public/private location settings
- **Reverse Geocoding** - OpenStreetMap Nominatim API integration
- **Browser Geolocation** - JavaScript-based location detection

### 📝 Multi-Step Registration
- **Wizard-Based Onboarding** - 6-step registration flow using Wicked Wizard
- **Flexible Contact Methods** - Email or phone-based registration
- **Profile Completion** - Username, bio, photo, and location setup
- **Step Validation** - Progress tracking with validation at each step

### 🌐 API & Integration
- **RESTful API (v1)** - Complete API with JWT authentication
- **Token Management** - Access and refresh token system
- **User Data Serialization** - Structured API responses
- **Email & SMS Integration** - Verification and notification systems

### 💼 Administrative Features
- **User Management** - Search, pagination, and account control
- **Role Assignment** - Dynamic role and permission management
- **Account Controls** - Admin-initiated locking/unlocking
- **System Protection** - Core role deletion prevention

### 🎨 Modern Frontend
- **Hotwire Stack** - Turbo + Stimulus for SPA-like experience
- **Tailwind CSS** - Responsive design with mobile-first approach
- **Import Maps** - No-build JavaScript module management
- **PWA Ready** - Progressive Web App scaffolding

### 📧 Communication System
- **Email Infrastructure** - Transactional emails with verification
- **SMS Integration** - Verification codes and notifications
- **Development Tools** - Letter Opener for email testing
- **Multi-language Support** - I18n with locale-based routing

### 🔧 Developer Experience
- **Comprehensive Testing** - RSpec with FactoryBot and Capybara
- **Coverage Reporting** - Combined Ruby/JavaScript coverage
- **Code Quality Tools** - RuboCop and Brakeman integration
- **Modern Rails Stack** - Rails 8 with Solid adapters for caching, jobs, and WebSockets

## Tech Stack

- **Ruby** 3.2+
- **Rails** 8.0.2
- **Database** Postgresl with Solid adapters
- **Frontend** Hotwire (Turbo + Stimulus) with Tailwind CSS
- **Testing** RSpec with SimpleCov
- **CI/CD** GitHub Actions with Codecov integration

## Using This Template

### Option 1: Use GitHub Template Feature
1. Click the "Use this template" button on GitHub
2. Create your new repository
3. Clone your new repository locally

### Option 2: Clone and Customize
1. Clone this repository
2. Remove the existing git history
3. Initialize as your own project

```bash
git clone https://github.com/antarr/jordan.git your-app-name
cd your-app-name
rm -rf .git
git init
git add .
git commit -m "Initial commit from Jordan template"
```

## Getting Started

### Prerequisites

- Ruby 3.2 or higher
- Rails 8.0.2
- SQLite3

### Installation

1. After creating your project from the template:
```bash
cd your-app-name
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

Visit http://localhost:3000 to see your application.

### First Steps After Installation

1. **Update Application Name**: Change the application name in `config/application.rb`
2. **Configure Email**: Update email settings in `config/environments/`
3. **Customize Roles**: Modify default roles and permissions in `db/seeds.rb`
4. **Update Branding**: Replace the coming soon page with your own landing page
5. **Configure Location Services**: Set up your preferred geocoding service

## Perfect For

This template is ideal for building:

### 🛒 **E-commerce Applications**
- User accounts with role-based permissions
- Location-based features for shipping/stores
- Admin panel for product and user management
- Secure authentication with 2FA

### 📱 **Social Media Platforms**
- Multi-step user onboarding
- Profile management with photos and bios
- Location sharing with privacy controls
- Role-based content moderation

### 🏢 **Enterprise Applications**
- Advanced role and permission systems
- Multi-method authentication (including WebAuthn)
- User management and admin controls
- API-first architecture for integrations

### 💼 **SaaS Products**
- JWT API authentication for external integrations
- User management with different access levels
- Comprehensive admin interface
- Modern, responsive frontend

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

This template is production-ready and configured for deployment with:

- **Kamal** - For containerized deployment to any server
- **Docker** - Complete containerization support
- **GitHub Actions** - Automated CI/CD pipeline with testing and coverage
- **Solid Adapters** - Database-backed infrastructure for scaling
- **Security Best Practices** - CSRF protection, secure headers, and more

### Deployment Checklist

Before deploying to production:

1. **Environment Variables**: Configure all required environment variables
2. **Email Provider**: Set up your email service (SendGrid, Mailgun, etc.)
3. **SMS Provider**: Configure SMS service for phone authentication
4. **Database**: Consider PostgreSQL for production instead of SQLite
5. **File Storage**: Configure cloud storage for file uploads
6. **SSL/TLS**: Ensure HTTPS is properly configured
7. **Monitoring**: Set up error tracking and performance monitoring

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
