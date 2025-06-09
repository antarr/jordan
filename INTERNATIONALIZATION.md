# Internationalization Support

This application now supports multiple languages: English, Spanish, and Brazilian Portuguese.

## Features

### Supported Languages
- **English (en)** - Default language
- **Spanish (es)** - Español
- **Brazilian Portuguese (pt-BR)** - Português (BR)

### URL Structure
All URLs now include the locale prefix:
- English: `/en/session/new`
- Spanish: `/es/session/new`  
- Portuguese: `/pt-BR/session/new`

### Language Detection
The application automatically detects the user's preferred language using:
1. URL parameter (`?locale=es`)
2. Session storage (remembers previous selection)
3. Browser Accept-Language header
4. Falls back to English (default)

### Language Switcher
A language switcher is available in the navigation bar that allows users to change languages instantly. The switcher shows:
- 🇺🇸 English
- 🇪🇸 Español  
- 🇧🇷 Português (BR)

## Implementation Details

### Configuration
- Available locales configured in `config/application.rb`
- Locale files in `config/locales/` directory
- Routes wrapped in locale scope in `config/routes.rb`

### Locale Files
All user-facing text is externalized to YAML files:
- `config/locales/en.yml` - English translations
- `config/locales/es.yml` - Spanish translations
- `config/locales/pt-BR.yml` - Brazilian Portuguese translations

### Features Translated
- Navigation elements (Sign In, Sign Up, Sign Out)
- Flash messages (success, error, alerts)
- Form buttons and labels
- Email subjects
- ActiveRecord error messages

### Technical Implementation
- `Localization` concern handles locale detection and setting
- Helper methods for language switching
- Route helpers automatically include locale parameters
- Session persistence of locale selection

## Usage Examples

### Accessing Different Languages
```
# English (default)
http://localhost:3000/en/session/new

# Spanish
http://localhost:3000/es/session/new

# Brazilian Portuguese  
http://localhost:3000/pt-BR/session/new
```

### Testing Internationalization
Run the internationalization test suite:
```bash
bundle exec rspec spec/features/internationalization_spec.rb
```

## Future Enhancements
- Add more languages as needed
- Implement user language preferences in database
- Add date/time localization
- Add number/currency formatting
- Implement RTL language support if needed