module Api
  module V1
    class AuthenticationController < Api::BaseController
      skip_before_action :authenticate_request, only: [:login]

      def login
        user = User.find_by(email: login_params[:email])

        if user&.authenticate(login_params[:password])
          if JwtService.refresh_tokens_enabled?
            access_token = JwtService.encode_access_token(user.id)
            refresh_token = generate_and_save_refresh_token(user)
            
            render json: {
              access_token: access_token,
              refresh_token: refresh_token,
              expires_in: Rails.application.config.jwt[:access_token_expiry].to_i,
              user: user_json(user)
            }, status: :ok
          else
            token = JwtService.encode_access_token(user.id)
            render json: {
              token: token,
              user: user_json(user)
            }, status: :ok
          end
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def logout
        if JwtService.refresh_tokens_enabled? && current_user
          current_user.update(refresh_token: nil, refresh_token_expires_at: nil)
        end
        
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      def refresh
        unless JwtService.refresh_tokens_enabled?
          render json: { error: 'Refresh tokens are not enabled' }, status: :not_implemented
          return
        end

        token = request.headers['Authorization']&.split(' ')&.last
        
        begin
          decoded = JwtService.decode_refresh_token(token)
          user = User.find_by(id: decoded[:user_id], refresh_token: token)
          
          if user && user.refresh_token_expires_at > Time.current
            access_token = JwtService.encode_access_token(user.id)
            
            render json: {
              access_token: access_token,
              expires_in: Rails.application.config.jwt[:access_token_expiry].to_i
            }, status: :ok
          else
            render json: { error: 'Invalid or expired refresh token' }, status: :unauthorized
          end
        rescue JWT::DecodeError, JWT::ExpiredSignature
          render json: { error: 'Invalid refresh token' }, status: :unauthorized
        end
      end

      private

      def login_params
        params.require(:authentication).permit(:email, :password)
      end

      def skip_authentication?
        action_name == 'login' || action_name == 'refresh'
      end
      
      def user_json(user)
        {
          id: user.id,
          email: user.email,
          username: user.username,
          bio: user.bio
        }
      end
      
      def generate_and_save_refresh_token(user)
        refresh_token = JwtService.encode_refresh_token(user.id)
        user.update(
          refresh_token: refresh_token,
          refresh_token_expires_at: Rails.application.config.jwt[:refresh_token_expiry].from_now
        )
        refresh_token
      end
    end
  end
end
