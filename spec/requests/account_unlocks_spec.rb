require 'rails_helper'

RSpec.describe 'AccountUnlocks', type: :request do
  describe 'GET /unlock-account/new' do
    it 'returns http success' do
      get '/en/unlock-account/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /unlock-account' do
    it 'redirects after processing' do
      post '/en/unlock-account', params: { email: 'test@example.com' }
      expect(response).to redirect_to('/en/session/new')
    end
  end

  describe 'GET /unlock-account/:token' do
    let!(:user) do
      create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: false,
                                            auto_unlock_token: 'test_token')
    end

    it 'unlocks account with valid token' do
      get '/en/unlock-account/test_token'
      expect(response).to redirect_to('/en/session/new')
    end

    it 'redirects with invalid token' do
      get '/en/unlock-account/invalid_token'
      expect(response).to redirect_to('/en/session/new')
    end
  end
end
