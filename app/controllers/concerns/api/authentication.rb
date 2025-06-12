module Api
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_request, unless: :skip_authentication?
    end

    private

    def authenticate_request
      header = request.headers['Authorization']
      header = header.split(' ').last if header

      begin
        @decoded = JwtService.decode(header)
        
        if JwtService.refresh_tokens_enabled? && @decoded[:type] == Rails.application.config.jwt[:refresh_token_type]
          render json: { error: 'Cannot use refresh token for authentication' }, status: :unauthorized
          return
        end
        
        @current_user = User.find(@decoded[:user_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :unauthorized
      rescue JWT::ExpiredSignature
        render json: { error: 'Token has expired' }, status: :unauthorized
      rescue JWT::DecodeError
        render json: { error: 'Invalid token' }, status: :unauthorized
      end
    end

    def current_user
      @current_user
    end

    def skip_authentication?
      false
    end
  end
end
