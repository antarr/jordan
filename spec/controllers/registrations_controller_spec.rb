require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'GET #new' do
    it 'renders the new template with a new user' do
      get :new
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:ok)
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'creates a new user, sends verification email, and redirects to login' do
        expect(EmailVerificationJob).to receive(:perform_later)
        
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq('newuser@example.com')
        expect(user.email_verified?).to be false
        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq("Account created successfully! Please check your email to verify your account.")
      end
    end

    context 'with invalid parameters' do
      context 'missing email' do
        let(:invalid_params) do
          {
            user: {
              email: '',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user and renders new template' do
          expect {
            post :create, params: invalid_params
          }.not_to change(User, :count)

          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:email]).to include("can't be blank")
        end
      end

      context 'invalid email format' do
        let(:invalid_params) do
          {
            user: {
              email: 'invalid-email',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user and renders new template' do
          expect {
            post :create, params: invalid_params
          }.not_to change(User, :count)

          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:email]).to include("is invalid")
        end
      end

      context 'password too short' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: '123',
              password_confirmation: '123'
            }
          }
        end

        it 'does not create a user and renders new template' do
          expect {
            post :create, params: invalid_params
          }.not_to change(User, :count)

          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:password]).to include("is too short (minimum is 6 characters)")
        end
      end

      context 'password confirmation does not match' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123',
              password_confirmation: 'different'
            }
          }
        end

        it 'does not create a user and renders new template' do
          expect {
            post :create, params: invalid_params
          }.not_to change(User, :count)

          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:password_confirmation]).to include("doesn't match Password")
        end
      end

      context 'duplicate email' do
        let!(:existing_user) { User.create!(email: 'test@example.com', password: 'password123') }
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user and renders new template' do
          expect {
            post :create, params: invalid_params
          }.not_to change(User, :count)

          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:email]).to include("has already been taken")
        end
      end
    end
  end
end