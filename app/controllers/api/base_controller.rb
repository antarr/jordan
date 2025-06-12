module Api
  class BaseController < ActionController::API
    include Api::Authentication

    rescue_from JWT::DecodeError, with: :unauthorized_response
    rescue_from JWT::ExpiredSignature, with: :unauthorized_response

    private

    def unauthorized_response(exception)
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
