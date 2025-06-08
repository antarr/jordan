require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  describe 'GET #index' do
    context 'when user is signed in and verified' do
      before do
        user.verify_email!
        session[:user_id] = user.id
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
        expect(response).to have_http_status(:ok)
      end

      it 'does not redirect' do
        get :index
        expect(response).not_to be_redirect
      end
    end

    context 'when user is signed in but not verified' do
      before { session[:user_id] = user.id }

      it 'redirects to login page' do
        get :index
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Please verify your email address to access the dashboard.')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login page' do
        get :index
        expect(response).to redirect_to(new_session_path)
      end

      it 'does not set an alert message (handled by require_authentication)' do
        get :index
        expect(flash[:alert]).to be_nil
      end

      it 'does not render the index template' do
        get :index
        expect(response).not_to render_template(:index)
      end
    end

    context 'when session has invalid user_id' do
      before { session[:user_id] = 'invalid' }

      it 'redirects to login (authentication required)' do
        get :index
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when session user_id is nil' do
      before { session[:user_id] = nil }

      it 'redirects to login page' do
        get :index
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe 'before_action callbacks' do
    context 'with verified user' do
      before do
        user.verify_email!
        session[:user_id] = user.id
      end

      it 'allows access to dashboard' do
        get :index
        expect(response).not_to be_redirect
        expect(response).to render_template(:index)
      end
    end

    context 'with unverified user' do
      before { session[:user_id] = user.id }

      it 'redirects to login with verification message' do
        get :index
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Please verify your email address to access the dashboard.')
      end
    end

    context 'without authentication' do
      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end