require 'rails_helper'

RSpec.describe Api::Authentication, type: :controller do
  controller(Api::BaseController) do
    def index
      render json: { message: 'Success', user_id: current_user.id }
    end
  end

  before do
    allow(Rails.application.config).to receive(:jwt).and_return({
                                                                  refresh_tokens_enabled: true,
                                                                  access_token_type: 'access',
                                                                  refresh_token_type: 'refresh',
                                                                  access_token_expiry: 15.minutes,
                                                                  refresh_token_expiry: 30.days
                                                                })
  end

  let(:user) { create(:user) }
  let(:valid_token) { JwtService.encode_access_token(user.id) }
  let(:expired_token) { JwtService.encode({ user_id: user.id, type: 'access' }, 1.second.ago) }

  describe 'authentication' do
    context 'with valid token' do
      it 'authenticates the request' do
        request.headers['Authorization'] = "Bearer #{valid_token}"
        get :index

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq(user.id)
      end
    end

    context 'without token' do
      it 'returns unauthorized' do
        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid token')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        request.headers['Authorization'] = 'Bearer invalid.token'
        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid token')
      end
    end

    context 'with expired token' do
      it 'returns unauthorized' do
        request.headers['Authorization'] = "Bearer #{expired_token}"
        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Token has expired')
      end
    end

    context 'when user does not exist' do
      it 'returns unauthorized' do
        token = JwtService.encode({ user_id: 999_999, type: 'access' })
        request.headers['Authorization'] = "Bearer #{token}"
        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
      end
    end

    context 'with refresh token' do
      it 'rejects refresh token for regular authentication' do
        refresh_token = JwtService.encode_refresh_token(user.id)
        request.headers['Authorization'] = "Bearer #{refresh_token}"
        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Cannot use refresh token for authentication')
      end
    end
  end

  describe '#current_user' do
    it 'returns the authenticated user' do
      request.headers['Authorization'] = "Bearer #{valid_token}"
      get :index

      expect(controller.send(:current_user)).to eq(user)
    end
  end
end
