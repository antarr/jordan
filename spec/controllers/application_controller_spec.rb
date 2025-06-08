require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action :require_authentication, only: [:authenticated_action]

    def index
      render plain: 'test'
    end

    def authenticated_action
      render plain: 'authenticated'
    end
  end

  before do
    routes.draw do
      get :index, to: 'anonymous#index'
      get :authenticated_action, to: 'anonymous#authenticated_action'
      get '/new_session_path', to: 'sessions#new', as: :new_session
    end
  end

  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  describe '#current_user' do
    context 'when user is signed in' do
      before { session[:user_id] = user.id }

      it 'returns the current user' do
        get :index
        expect(controller.send(:current_user)).to eq(user)
      end
    end

    context 'when user is not signed in' do
      it 'returns nil' do
        get :index
        expect(controller.send(:current_user)).to be_nil
      end
    end

    context 'when user_id in session is invalid' do
      before { session[:user_id] = 999999 }

      it 'returns nil' do
        get :index
        expect(controller.send(:current_user)).to be_nil
      end
    end
  end

  describe '#user_signed_in?' do
    context 'when user is signed in' do
      before { session[:user_id] = user.id }

      it 'returns true' do
        get :index
        expect(controller.send(:user_signed_in?)).to be true
      end
    end

    context 'when user is not signed in' do
      it 'returns false' do
        get :index
        expect(controller.send(:user_signed_in?)).to be false
      end
    end
  end

  describe '#sign_in' do
    it 'sets the user_id in session' do
      get :index
      controller.send(:sign_in, user)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe '#sign_out' do
    before { session[:user_id] = user.id }

    it 'clears the user_id from session' do
      get :index
      controller.send(:sign_out)
      expect(session[:user_id]).to be_nil
    end
  end

  describe '#require_authentication' do
    context 'when user is signed in' do
      before { session[:user_id] = user.id }

      it 'allows access to protected action' do
        get :authenticated_action
        expect(response.body).to eq('authenticated')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to new_session_path' do
        get :authenticated_action
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe 'helper methods' do
    it 'makes current_user available to views' do
      expect(controller.class._helper_methods).to include(:current_user)
    end

    it 'makes user_signed_in? available to views' do
      expect(controller.class._helper_methods).to include(:user_signed_in?)
    end
  end
end