require 'rails_helper'

RSpec.describe 'Api::V1::Authentication', type: :request do
  describe 'POST /api/v1/login' do
    let(:user) { create(:user, email: 'test@example.com', password: 'password123') }
    
    context 'when refresh tokens disabled' do
      before do
        allow(Rails.application.config).to receive(:jwt).and_return({
          refresh_tokens_enabled: false
        })
      end

      it 'returns a single JWT token' do
        post '/api/v1/login', params: {
          authentication: {
            email: user.email,
            password: 'password123'
          }
        }

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['access_token']).to be_nil
        expect(json_response['refresh_token']).to be_nil
        expect(json_response['user']).to include(
          'id' => user.id,
          'email' => user.email,
          'username' => user.username,
          'bio' => user.bio
        )
      end
    end

    context 'when refresh tokens enabled' do
      before do
        allow(Rails.application.config).to receive(:jwt).and_return({
          refresh_tokens_enabled: true,
          access_token_expiry: 15.minutes,
          refresh_token_expiry: 30.days,
          access_token_type: 'access',
          refresh_token_type: 'refresh'
        })
      end

      it 'returns access and refresh tokens' do
        post '/api/v1/login', params: {
          authentication: {
            email: user.email,
            password: 'password123'
          }
        }

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['access_token']).to be_present
        expect(json_response['refresh_token']).to be_present
        expect(json_response['expires_in']).to eq(900) # 15 minutes
        expect(json_response['token']).to be_nil
        
        # Verify tokens are stored
        user.reload
        expect(user.refresh_token).to eq(json_response['refresh_token'])
        expect(user.refresh_token_expires_at).to be_within(1.minute).of(30.days.from_now)
      end
    end

    context 'with invalid email' do
      it 'returns unauthorized' do
        post '/api/v1/login', params: {
          authentication: {
            email: 'wrong@example.com',
            password: 'password123'
          }
        }

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end

    context 'with invalid password' do
      it 'returns unauthorized' do
        post '/api/v1/login', params: {
          authentication: {
            email: user.email,
            password: 'wrongpassword'
          }
        }

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end
  end

  describe 'DELETE /api/v1/logout' do
    let(:user) { create(:user) }
    
    context 'when refresh tokens disabled' do
      let(:token) { JwtService.encode_access_token(user.id) }
      let(:headers) { { 'Authorization' => "Bearer #{token}" } }

      before do
        allow(Rails.application.config).to receive(:jwt).and_return({
          refresh_tokens_enabled: false,
          access_token_type: 'access'
        })
      end

      it 'returns success message' do
        delete '/api/v1/logout', headers: headers

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Logged out successfully')
      end
    end

    context 'when refresh tokens enabled' do
      let(:token) { JwtService.encode_access_token(user.id) }
      let(:headers) { { 'Authorization' => "Bearer #{token}" } }

      before do
        allow(Rails.application.config).to receive(:jwt).and_return({
          refresh_tokens_enabled: true,
          access_token_type: 'access',
          refresh_token_type: 'refresh',
          access_token_expiry: 15.minutes,
          refresh_token_expiry: 30.days
        })
        
        user.update(
          refresh_token: 'some-refresh-token',
          refresh_token_expires_at: 30.days.from_now
        )
      end

      it 'clears refresh token' do
        delete '/api/v1/logout', headers: headers

        expect(response).to have_http_status(:ok)
        
        user.reload
        expect(user.refresh_token).to be_nil
        expect(user.refresh_token_expires_at).to be_nil
      end
    end

    context 'without token' do
      it 'returns unauthorized' do
        delete '/api/v1/logout'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        delete '/api/v1/logout', headers: { 'Authorization' => 'Bearer invalid.token' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/refresh' do
    let(:user) { create(:user) }

    context 'when refresh tokens disabled' do
      before do
        allow(Rails.application.config).to receive(:jwt).and_return({
          refresh_tokens_enabled: false
        })
      end

      it 'returns not implemented' do
        post '/api/v1/refresh', headers: { 'Authorization' => 'Bearer some-token' }

        expect(response).to have_http_status(:not_implemented)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Refresh tokens are not enabled')
      end
    end

    context 'when refresh tokens enabled' do
      before do
        allow(Rails.application.config).to receive(:jwt).and_return({
          refresh_tokens_enabled: true,
          access_token_expiry: 15.minutes,
          refresh_token_expiry: 30.days,
          access_token_type: 'access',
          refresh_token_type: 'refresh'
        })
      end

      context 'with valid refresh token' do
        let(:refresh_token) { JwtService.encode_refresh_token(user.id) }

        before do
          user.update(
            refresh_token: refresh_token,
            refresh_token_expires_at: 30.days.from_now
          )
        end

        it 'returns new access token' do
          post '/api/v1/refresh', headers: { 'Authorization' => "Bearer #{refresh_token}" }

          expect(response).to have_http_status(:ok)
          
          json_response = JSON.parse(response.body)
          expect(json_response['access_token']).to be_present
          expect(json_response['expires_in']).to eq(900)
          
          # Verify it's a valid access token
          decoded = JwtService.decode(json_response['access_token'])
          expect(decoded[:user_id]).to eq(user.id)
          expect(decoded[:type]).to eq('access')
        end
      end

      context 'with expired refresh token' do
        let(:refresh_token) { JwtService.encode_refresh_token(user.id) }

        before do
          user.update(
            refresh_token: refresh_token,
            refresh_token_expires_at: 1.day.ago
          )
        end

        it 'returns unauthorized' do
          post '/api/v1/refresh', headers: { 'Authorization' => "Bearer #{refresh_token}" }

          expect(response).to have_http_status(:unauthorized)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Invalid or expired refresh token')
        end
      end

      context 'with invalid refresh token' do
        it 'returns unauthorized' do
          post '/api/v1/refresh', headers: { 'Authorization' => 'Bearer invalid.token' }

          expect(response).to have_http_status(:unauthorized)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Invalid refresh token')
        end
      end

      context 'with access token instead of refresh token' do
        let(:access_token) { JwtService.encode_access_token(user.id) }

        it 'returns unauthorized' do
          post '/api/v1/refresh', headers: { 'Authorization' => "Bearer #{access_token}" }

          expect(response).to have_http_status(:unauthorized)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Invalid refresh token')
        end
      end
    end
  end
end