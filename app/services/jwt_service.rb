class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base

  class << self
    def encode_access_token(user_id)
      exp = if refresh_tokens_enabled?
              Rails.application.config.jwt[:access_token_expiry].from_now
            else
              24.hours.from_now
            end

      encode({ user_id: user_id, type: Rails.application.config.jwt[:access_token_type] }, exp)
    end

    def encode_refresh_token(user_id)
      raise 'Refresh tokens are not enabled' unless refresh_tokens_enabled?

      exp = Rails.application.config.jwt[:refresh_token_expiry].from_now
      encode({ user_id: user_id, type: Rails.application.config.jwt[:refresh_token_type] }, exp)
    end

    def encode(payload, exp = 24.hours.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, SECRET_KEY)
    end

    def decode(token)
      body = JWT.decode(token, SECRET_KEY)[0]
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError => e
      raise e
    end

    def decode_refresh_token(token)
      decoded = decode(token)

      unless decoded[:type] == Rails.application.config.jwt[:refresh_token_type]
        raise JWT::DecodeError, 'Invalid token type'
      end

      decoded
    end

    def refresh_tokens_enabled?
      Rails.application.config.jwt[:refresh_tokens_enabled]
    end
  end
end
