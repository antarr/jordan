WebAuthn.configure do |config|
  # This value needs to match your website's origins
  config.allowed_origins = case Rails.env
                           when 'production'
                             [ENV.fetch('WEBAUTHN_ORIGIN', 'https://your-domain.com')]
                           when 'staging'
                             [ENV.fetch('WEBAUTHN_ORIGIN', 'https://staging.your-domain.com')]
                           else
                             ['http://localhost:3000', 'https://ragged.test']
                           end

  # Relying Party name for display purposes
  config.rp_name = ENV.fetch('WEBAUTHN_RP_NAME', 'Ragged')

  # Credential options
  config.credential_options_timeout = 120_000

  # Acceptable credential creation and authentication algorithms
  config.algorithms = %w[ES256 PS256 RS256]

  # Relying Party ID (should be the domain name)
  config.rp_id = case Rails.env
                 when 'production'
                   ENV.fetch('WEBAUTHN_RP_ID', 'your-domain.com')
                 when 'staging'
                   ENV.fetch('WEBAUTHN_RP_ID', 'staging.your-domain.com')
                 else
                   # Try to detect the current domain automatically
                   if defined?(Rails::Server) && Rails::Server.new.options[:Host]
                     Rails::Server.new.options[:Host]
                   else
                     # Default fallback for different local setups
                     ENV.fetch('WEBAUTHN_RP_ID', 'localhost')
                   end
                 end
end
