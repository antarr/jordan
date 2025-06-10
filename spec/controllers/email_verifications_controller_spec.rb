require 'rails_helper'

RSpec.describe EmailVerificationsController, type: :controller do
  describe 'GET #show' do
    let(:user) do
      User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123',
                   contact_method: 'email', registration_step: 1, username: 'testuser', bio: 'This is a test bio that meets the minimum length requirement for the user model.')
    end

    context 'with valid token' do
      it 'verifies the user email and signs them in' do
        token = user.email_verification_token
        get :show, params: { token: token }

        user.reload
        expect(user.email_verified?).to be true
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq('Your email has been verified successfully!')
      end
    end

    context 'with invalid token' do
      it 'redirects to login with error message' do
        get :show, params: { token: 'invalid_token' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Invalid or expired verification link.')
      end
    end

    context 'with expired token' do
      it 'redirects to login with error message' do
        user.update!(email_verification_token_expires_at: 1.hour.ago)
        token = user.email_verification_token
        get :show, params: { token: token }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Invalid or expired verification link.')
      end
    end

    context 'with missing token' do
      it 'redirects to login with error message' do
        get :show, params: { token: '' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Invalid or expired verification link.')
      end
    end
  end

  describe 'POST #create' do
    let(:user) do
      User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123',
                   contact_method: 'email', registration_step: 1, username: 'testuser2', bio: 'This is a test bio that meets the minimum length requirement for the user model.')
    end

    context 'when user is signed in' do
      before { session[:user_id] = user.id }

      context 'when email is not verified' do
        it 'sends verification email' do
          expect(EmailVerificationJob).to receive(:perform_later).with(user)
          post :create

          expect(response).to redirect_to(dashboard_path)
          expect(flash[:notice]).to eq('Verification email sent! Please check your inbox.')
        end
      end

      context 'when email is already verified' do
        before { user.verify_email! }

        it 'redirects with notice' do
          post :create

          expect(response).to redirect_to(dashboard_path)
          expect(flash[:notice]).to eq('Your email is already verified.')
        end
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        post :create
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
