require 'rails_helper'

RSpec.describe PhoneSessionsController, type: :controller do
  # Skip template rendering for controller tests
  render_views false

  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let(:phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: Time.current) }

    context 'login with SMS code' do
      before do
        phone_user.generate_sms_verification_code!
      end

      it 'logs in with valid SMS code' do
        post :create, params: { 
          phone: phone_user.phone, 
          sms_code: phone_user.sms_verification_code 
        }
        
        expect(session[:user_id]).to eq(phone_user.id)
        expect(response).to redirect_to(dashboard_path)
      end

      it 'rejects invalid SMS code' do
        post :create, params: { 
          phone: phone_user.phone, 
          sms_code: '000000' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_sms_code'))
      end

      it 'rejects expired SMS code' do
        phone_user.update!(sms_verification_code_expires_at: 1.hour.ago)
        
        post :create, params: { 
          phone: phone_user.phone, 
          sms_code: phone_user.sms_verification_code 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_sms_code'))
      end
    end

    context 'login with password' do
      let(:phone_user_with_password) { 
        create(:user, :phone_user, :step_two, 
               phone_verified_at: Time.current,
               password: 'ValidPass123!', 
               password_confirmation: 'ValidPass123!')
      }

      it 'logs in with valid password' do
        post :create, params: { 
          phone: phone_user_with_password.phone, 
          password: 'ValidPass123!' 
        }
        
        expect(session[:user_id]).to eq(phone_user_with_password.id)
        expect(response).to redirect_to(dashboard_path)
      end

      it 'rejects invalid password' do
        post :create, params: { 
          phone: phone_user_with_password.phone, 
          password: 'WrongPassword' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_password'))
      end
    end

    context 'with non-existent phone number' do
      it 'returns phone not found error' do
        post :create, params: { 
          phone: '+1234567890', 
          sms_code: '123456' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.phone_not_found'))
      end
    end

    context 'with unverified phone number' do
      let(:unverified_phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: nil) }

      it 'rejects login attempt' do
        post :create, params: { 
          phone: unverified_phone_user.phone, 
          password: 'ValidPass123!' 
        }
        
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.phone_not_verified'))
      end
    end

    context 'with missing credentials' do
      it 'requires either SMS code or password' do
        post :create, params: { phone: phone_user.phone }
        
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.missing_credentials'))
      end
    end

    context 'with missing phone parameter' do
      it 'returns error' do
        post :create, params: { sms_code: '123456' }
        
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.phone_not_found'))
      end
    end
  end

  describe 'POST #request_sms' do
    let(:phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: Time.current) }

    context 'with valid phone number' do
      it 'sends SMS login code' do
        expect(SmsService).to receive(:send_login_code)
          .with(phone_user.phone, anything)
          .and_return(true)
        
        post :request_sms, params: { phone: phone_user.phone }
        
        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['message']).to eq(I18n.t('phone_sessions.request_sms.sent'))
        
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

      it 'handles SMS service failure' do
        allow(SmsService).to receive(:send_login_code).and_return(false)
        
        post :request_sms, params: { phone: phone_user.phone }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('phone_sessions.request_sms.failed'))
      end

      it 'generates new verification code' do
        allow(SmsService).to receive(:send_login_code).and_return(true)
        old_code = phone_user.sms_verification_code
        
        post :request_sms, params: { phone: phone_user.phone }
        
        expect(phone_user.reload.sms_verification_code).not_to eq(old_code)
        expect(phone_user.sms_verification_code).to match(/\A\d{6}\z/)
      end
    end

    context 'with non-existent phone number' do
      it 'returns phone not found error' do
        post :request_sms, params: { phone: '+1234567890' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('phone_sessions.request_sms.phone_not_found'))
      end
    end

    context 'with unverified phone number' do
      let(:unverified_phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: nil) }

      it 'returns phone not verified error' do
        post :request_sms, params: { phone: unverified_phone_user.phone }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('phone_sessions.request_sms.phone_not_verified'))
      end
    end

    context 'with missing phone parameter' do
      it 'returns phone not found error' do
        post :request_sms, params: {}
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('phone_sessions.request_sms.phone_not_found'))
      end
    end
  end
end