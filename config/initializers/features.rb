# Feature flags configuration
Rails.application.configure do
  config.features = {
    phone_registration_enabled: ENV.fetch('PHONE_REGISTRATION_ENABLED', 'true') == 'true'
  }
end
