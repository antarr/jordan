require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user, :email_user, :step_two, :unverified) }

  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    context 'with valid credentials' do
      context 'for verified user' do
        before { user.verify_email! }

        it 'signs in the user and redirects to dashboard' do
          post :create, params: { email: user.email, password: user.password }
          
          expect(session[:user_id]).to eq(user.id)
          expect(response).to redirect_to(dashboard_path)
        end
      end

      context 'for unverified user' do
        it 'redirects to login with verification message' do
          post :create, params: { email: user.email, password: user.password }
          
          expect(session[:user_id]).to be_nil
          expect(response).to redirect_to(new_session_path)
          expect(flash[:alert]).to eq("Please verify your email address before signing in. Check your inbox for the verification link.")
        end
      end
    end

    context 'with invalid email' do
      it 'renders new template with error message' do
        post :create, params: { email: Faker::Internet.email, password: user.password }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to eq("Invalid email or password.")
      end
    end

    context 'with invalid password' do
      it 'renders new template with error message' do
        post :create, params: { email: user.email, password: Faker::Internet.password }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to eq("Invalid email or password.")
      end
    end

    context 'with empty credentials' do
      it 'renders new template with error message' do
        post :create, params: { email: '', password: '' }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to eq("Invalid email or password.")
      end
    end
  end

  describe 'DELETE #destroy' do
    before { session[:user_id] = user.id }

    it 'signs out the user and redirects to login' do
      delete :destroy
      
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(new_session_path)
    end
  end
end