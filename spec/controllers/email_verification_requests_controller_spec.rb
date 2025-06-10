require 'rails_helper'

RSpec.describe EmailVerificationRequestsController, type: :controller do
  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with existing unverified user' do
      let!(:user) do
        User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123',
                     contact_method: 'email', registration_step: 1, username: 'testuser', bio: 'This is a test bio that meets the minimum length requirement for the user model.')
      end

      it 'sends verification email and redirects' do
        expect(EmailVerificationJob).to receive(:perform_later).with(user)
        post :create, params: { email: 'test@example.com' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('controllers.email_verification_requests.create.sent'))
      end

      it 'handles case insensitive email' do
        expect(EmailVerificationJob).to receive(:perform_later).with(user)
        post :create, params: { email: 'TEST@EXAMPLE.COM' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('controllers.email_verification_requests.create.sent'))
      end

      it 'handles email with whitespace' do
        expect(EmailVerificationJob).to receive(:perform_later).with(user)
        post :create, params: { email: '  test@example.com  ' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('controllers.email_verification_requests.create.sent'))
      end
    end

    context 'with existing verified user' do
      let!(:user) do
        User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123',
                     contact_method: 'email', registration_step: 1, username: 'testuser', bio: 'This is a test bio that meets the minimum length requirement for the user model.', email_verified_at: Time.current)
      end

      it 'redirects with same notice for security' do
        post :create, params: { email: 'test@example.com' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('controllers.email_verification_requests.create.sent'))
      end
    end

    context 'with non-existing user' do
      it 'shows same message for security' do
        post :create, params: { email: 'nonexistent@example.com' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('controllers.email_verification_requests.create.sent'))
      end
    end
  end
end
