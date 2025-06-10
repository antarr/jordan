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
    let(:phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: Time.current) }

    context 'with explicit login types' do
      it 'handles email login when login_type is email' do
        user.verify_email!
        
        post :create, params: { 
          login_type: 'email',
          email: user.email, 
          password: user.password 
        }
        
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(dashboard_path)
      end

      it 'defaults to email login when no login_type specified' do
        user.verify_email!
        
        post :create, params: { 
          email: user.email, 
          password: user.password 
        }
        
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'with phone login type' do
      before do
        phone_user.generate_sms_verification_code!
      end

      it 'handles phone login with SMS code' do
        post :create, params: { 
          login_type: 'phone',
          phone: phone_user.phone, 
          sms_code: phone_user.sms_verification_code 
        }
        
        expect(session[:user_id]).to eq(phone_user.id)
        expect(response).to redirect_to(dashboard_path)
      end

      it 'handles phone login with password' do
        phone_user_with_password = create(:user, :phone_user, :step_two, 
                                         phone_verified_at: Time.current,
                                         password: 'ValidPass123!', 
                                         password_confirmation: 'ValidPass123!')
        
        post :create, params: { 
          login_type: 'phone',
          phone: phone_user_with_password.phone, 
          password: 'ValidPass123!' 
        }
        
        expect(session[:user_id]).to eq(phone_user_with_password.id)
        expect(response).to redirect_to(dashboard_path)
      end

      it 'rejects login with non-existent phone' do
        post :create, params: { 
          login_type: 'phone',
          phone: '+1234567890', 
          sms_code: '123456' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.phone_not_found'))
      end

      it 'rejects login with unverified phone' do
        unverified_phone_user = create(:user, :phone_user, :step_two, phone_verified_at: nil)
        
        post :create, params: { 
          login_type: 'phone',
          phone: unverified_phone_user.phone, 
          sms_code: '123456' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.phone_not_verified'))
      end

      it 'rejects login with invalid SMS code' do
        post :create, params: { 
          login_type: 'phone',
          phone: phone_user.phone, 
          sms_code: '000000' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_sms_code'))
      end

      it 'rejects login with invalid password' do
        phone_user_with_password = create(:user, :phone_user, :step_two, 
                                         phone_verified_at: Time.current,
                                         password: 'ValidPass123!', 
                                         password_confirmation: 'ValidPass123!')
        
        post :create, params: { 
          login_type: 'phone',
          phone: phone_user_with_password.phone, 
          password: 'WrongPassword' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_password'))
      end

      it 'rejects login when no password_digest exists but password provided' do
        post :create, params: { 
          login_type: 'phone',
          phone: phone_user.phone, 
          password: 'SomePassword' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_password'))
      end

      it 'rejects login with missing credentials' do
        post :create, params: { 
          login_type: 'phone',
          phone: phone_user.phone
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.missing_credentials'))
      end
    end

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
          expect(flash[:alert]).to eq(I18n.t('controllers.sessions.create.unverified_email'))
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

  describe 'POST #request_sms' do
    let(:phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: Time.current) }

    context 'with valid phone number' do
      it 'sends SMS code and returns success' do
        expect(SmsService).to receive(:send_login_code)
          .with(phone_user.phone, anything)
          .and_return(true)
        
        post :request_sms, params: { phone: phone_user.phone }
        
        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['message']).to eq(I18n.t('controllers.sessions.request_sms.sent'))
        
        # In test environment, development_sms_code should not be included
        expect(response_data).not_to have_key('development_sms_code')
      end
      
      it 'includes development SMS code in development environment' do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(SmsService).to receive(:send_login_code).and_return(true)
        
        post :request_sms, params: { phone: phone_user.phone }
        
        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data).to have_key('development_sms_code')
        expect(response_data['development_sms_code']).to match(/\A\d{6}\z/)
      end

      it 'generates new verification code' do
        allow(SmsService).to receive(:send_login_code).and_return(true)
        old_code = phone_user.sms_verification_code
        
        post :request_sms, params: { phone: phone_user.phone }
        
        expect(phone_user.reload.sms_verification_code).not_to eq(old_code)
        expect(phone_user.sms_verification_code).to match(/\A\d{6}\z/)
      end

      it 'handles SMS service failure' do
        allow(SmsService).to receive(:send_login_code).and_return(false)
        
        post :request_sms, params: { phone: phone_user.phone }
        
        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data['error']).to eq(I18n.t('controllers.sessions.request_sms.failed'))
      end
    end

    context 'with non-existent phone number' do
      it 'returns phone not found error' do
        post :request_sms, params: { phone: '+1234567890' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data['error']).to eq(I18n.t('controllers.sessions.request_sms.phone_not_found'))
      end
    end

    context 'with unverified phone number' do
      it 'returns phone not verified error' do
        unverified_phone_user = create(:user, :phone_user, :step_two, phone_verified_at: nil)
        
        post :request_sms, params: { phone: unverified_phone_user.phone }
        
        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data['error']).to eq(I18n.t('controllers.sessions.request_sms.phone_not_verified'))
      end
    end

    context 'with missing phone parameter' do
      it 'returns phone not found error' do
        post :request_sms, params: {}
        
        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data['error']).to eq(I18n.t('controllers.sessions.request_sms.phone_not_found'))
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