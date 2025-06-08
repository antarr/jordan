require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  describe 'GET #index' do
    context 'when user is signed in' do
      before { session[:user_id] = user.id }

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

    context 'when user is not signed in' do
      it 'redirects to login page' do
        get :index
        expect(response).to redirect_to(new_session_path)
      end

      it 'sets an alert message' do
        get :index
        expect(flash[:alert]).to eq('Please log in to access the dashboard.')
      end

      it 'does not render the index template' do
        get :index
        expect(response).not_to render_template(:index)
      end
    end

    context 'when session has invalid user_id' do
      before { session[:user_id] = 'invalid' }

      it 'still allows access (session presence check only)' do
        get :index
        expect(response).to render_template(:index)
        expect(response).to have_http_status(:ok)
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

  describe 'before_action :require_login' do
    it 'is called before index action' do
      expect(controller).to receive(:require_login).and_call_original
      session[:user_id] = user.id
      get :index
    end
  end

  describe '#require_login' do
    context 'when user_id exists in session' do
      before { session[:user_id] = user.id }

      it 'does not redirect' do
        get :index
        expect(response).not_to be_redirect
      end

      it 'does not set flash message' do
        get :index
        expect(flash[:alert]).to be_nil
      end
    end

    context 'when user_id does not exist in session' do
      it 'redirects to new_session_path' do
        get :index
        expect(response).to redirect_to(new_session_path)
      end

      it 'sets appropriate alert message' do
        get :index
        expect(flash[:alert]).to eq('Please log in to access the dashboard.')
      end
    end
  end
end