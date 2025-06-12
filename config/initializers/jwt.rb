Rails.application.config.jwt = {
  # Feature flag to enable/disable refresh tokens
  refresh_tokens_enabled: ENV.fetch('JWT_REFRESH_TOKENS_ENABLED', 'false') == 'true',

  # Token expiration times
  access_token_expiry: ENV.fetch('JWT_ACCESS_TOKEN_EXPIRY_MINUTES', '15').to_i.minutes,
  refresh_token_expiry: ENV.fetch('JWT_REFRESH_TOKEN_EXPIRY_DAYS', '30').to_i.days,

  # Token types for validation
  access_token_type: 'access',
  refresh_token_type: 'refresh'
}
