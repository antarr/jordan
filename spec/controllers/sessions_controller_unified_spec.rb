require 'rails_helper'

RSpec.describe SessionsController, 'Unified Login', type: :controller do
  render_views false

  describe 'POST #create with unified login form' do
    context 'email login' do
      let(:email_user) do
        create(:user, :email_user, :verified, password: 'ValidPass123!', password_confirmation: 'ValidPass123!')
      end

      it 'logs in with valid email and password' do
        post :create, params: {
          email: email_user.email,
          password: 'ValidPass123!'
        }

        expect(session[:user_id]).to eq(email_user.id)
        expect(response).to redirect_to(dashboard_path)
      end

      it 'rejects invalid email credentials' do
        post :create, params: {
          email: 'wrong@example.com',
          password: 'ValidPass123!'
        }

        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq(I18n.t('controllers.sessions.create.invalid_credentials'))
      end

      it 'rejects unverified email user' do
        unverified_user = create(:user, :email_user, :unverified, password: 'ValidPass123!',
                                                                  password_confirmation: 'ValidPass123!')

        post :create, params: {
          email: unverified_user.email,
          password: 'ValidPass123!'
        }

        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('controllers.sessions.create.unverified_email'))
      end
    end

    context 'phone login' do
      let(:phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: Time.current) }

      context 'with SMS code' do
        before do
          phone_user.generate_sms_verification_code!
        end

        it 'logs in with valid SMS code' do
          post :create, params: {
            login_type: 'phone',
            phone: phone_user.phone,
            sms_code: phone_user.sms_verification_code
          }

          expect(session[:user_id]).to eq(phone_user.id)
          expect(response).to redirect_to(dashboard_path)
        end

        it 'clears SMS code after successful login' do
          post :create, params: {
            login_type: 'phone',
            phone: phone_user.phone,
            sms_code: phone_user.sms_verification_code
          }

          expect(phone_user.reload.sms_verification_code).to be_nil
          expect(phone_user.reload.sms_verification_code_expires_at).to be_nil
        end

        it 'rejects invalid SMS code' do
          post :create, params: {
            login_type: 'phone',
            phone: phone_user.phone,
            sms_code: '000000'
          }

          expect(session[:user_id]).to be_nil
          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_sms_code'))
        end
      end

      context 'with password' do
        let(:phone_user_with_password) do
          create(:user, :phone_user, :step_two,
                 phone_verified_at: Time.current,
                 password: 'ValidPass123!',
                 password_confirmation: 'ValidPass123!')
        end

        it 'logs in with valid password' do
          post :create, params: {
            login_type: 'phone',
            phone: phone_user_with_password.phone,
            password: 'ValidPass123!'
          }

          expect(session[:user_id]).to eq(phone_user_with_password.id)
          expect(response).to redirect_to(dashboard_path)
        end

        it 'rejects invalid password' do
          post :create, params: {
            login_type: 'phone',
            phone: phone_user_with_password.phone,
            password: 'WrongPassword'
          }

          expect(session[:user_id]).to be_nil
          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.invalid_password'))
        end
      end

      context 'with missing credentials' do
        it 'requires either SMS code or password' do
          post :create, params: {
            login_type: 'phone',
            phone: phone_user.phone
          }

          expect(session[:user_id]).to be_nil
          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.missing_credentials'))
        end
      end

      context 'with non-existent phone' do
        it 'returns phone not found error' do
          post :create, params: {
            login_type: 'phone',
            phone: '+1234567890',
            password: 'ValidPass123!'
          }

          expect(session[:user_id]).to be_nil
          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.phone_not_found'))
        end
      end

      context 'with unverified phone' do
        let(:unverified_phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: nil) }

        it 'rejects login attempt' do
          post :create, params: {
            login_type: 'phone',
            phone: unverified_phone_user.phone,
            password: 'ValidPass123!'
          }

          expect(session[:user_id]).to be_nil
          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.phone_not_verified'))
        end
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
        expect(response_data['message']).to eq(I18n.t('controllers.sessions.request_sms.sent'))

        # In test environment, development_sms_code should not be included
        expect(response_data).not_to have_key('development_sms_code')
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
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('controllers.sessions.request_sms.phone_not_found'))
      end
    end

    context 'with unverified phone number' do
      let(:unverified_phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: nil) }

      it 'returns phone not verified error' do
        post :request_sms, params: { phone: unverified_phone_user.phone }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('controllers.sessions.request_sms.phone_not_verified'))
      end
    end
  end
end
