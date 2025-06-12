require 'rails_helper'

RSpec.describe TwoFactorVerificationsController, type: :controller do
  let(:user) { create(:user, :complete_registration, two_factor_enabled: true) }
  let!(:credential) { create(:webauthn_credential, user: user) }

  describe 'GET #show' do
    context 'with pending user in session' do
      before do
        session[:pending_user_id] = user.id
      end

      it 'renders the show template' do
        get :show
        expect(response).to render_template(:show)
      end

      it 'assigns the user' do
        get :show
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'without pending user in session' do
      it 'redirects to sign in' do
        get :show
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Please sign in first.')
      end
    end
  end

  describe 'POST #verify' do
    context 'with pending user and verified 2FA' do
      before do
        session[:pending_user_id] = user.id
        session[:two_factor_verified] = true
      end

      it 'completes the login' do
        post :verify
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq('Successfully signed in with two-factor authentication.')
      end

      it 'clears session data' do
        post :verify
        expect(session[:pending_user_id]).to be_nil
        expect(session[:two_factor_verified]).to be_nil
      end

      it 'signs in the user' do
        post :verify
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'with pending user but unverified 2FA' do
      before do
        session[:pending_user_id] = user.id
        session[:two_factor_verified] = false
      end

      it 'redirects back to 2FA page' do
        post :verify
        expect(response).to redirect_to(two_factor_verification_path)
        expect(flash[:alert]).to eq('Two-factor authentication is required.')
      end

      it 'does not sign in the user' do
        post :verify
        expect(session[:user_id]).to be_nil
      end
    end

    context 'without pending user in session' do
      it 'redirects to sign in' do
        post :verify
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Please sign in first.')
      end
    end
  end
end
