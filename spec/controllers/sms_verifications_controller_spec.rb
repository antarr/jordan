require 'rails_helper'

RSpec.describe SmsVerificationsController, type: :controller do
  describe 'POST #verify' do
    let(:phone_user) { create(:user, :phone_user, :step_two) }

    before do
      phone_user.generate_sms_verification_code!
    end

    context 'with valid verification code' do
      it 'verifies the phone number and redirects to dashboard' do
        post :verify, params: {
          phone: phone_user.phone,
          code: phone_user.sms_verification_code
        }

        expect(phone_user.reload.phone_verified?).to be true
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq(I18n.t('sms_verifications.verify.success'))
      end

      it 'clears the verification code' do
        post :verify, params: {
          phone: phone_user.phone,
          code: phone_user.sms_verification_code
        }

        expect(phone_user.reload.sms_verification_code).to be_nil
        expect(phone_user.reload.sms_verification_code_expires_at).to be_nil
      end
    end

    context 'with invalid verification code' do
      it 'returns error for wrong code' do
        post :verify, params: {
          phone: phone_user.phone,
          code: '000000'
        }

        expect(phone_user.reload.phone_verified?).to be false
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.verify.invalid_code'))
      end

      it 'returns error for expired code' do
        phone_user.update!(sms_verification_code_expires_at: 1.hour.ago)

        post :verify, params: {
          phone: phone_user.phone,
          code: phone_user.sms_verification_code
        }

        expect(phone_user.reload.phone_verified?).to be false
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.verify.invalid_code'))
      end
    end

    context 'with non-existent phone number' do
      it 'returns user not found error' do
        post :verify, params: {
          phone: '+1234567890',
          code: '123456'
        }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.verify.user_not_found'))
      end
    end

    context 'with missing parameters' do
      it 'handles missing phone parameter' do
        post :verify, params: { code: '123456' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.verify.user_not_found'))
      end

      it 'handles missing code parameter' do
        post :verify, params: { phone: phone_user.phone }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.verify.invalid_code'))
      end
    end
  end

  describe 'POST #resend' do
    let(:phone_user) { create(:user, :phone_user, :step_two) }

    context 'with valid phone number' do
      it 'sends new verification code' do
        expect(SmsVerificationJob).to receive(:perform_later).with(phone_user)

        post :resend, params: { phone: phone_user.phone }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('sms_verifications.resend.sent'))
      end

      it 'generates new verification code' do
        old_code = phone_user.sms_verification_code

        post :resend, params: { phone: phone_user.phone }

        expect(phone_user.reload.sms_verification_code).not_to eq(old_code)
        expect(phone_user.sms_verification_code).to match(/\A\d{6}\z/)
      end
    end

    context 'with already verified phone' do
      it 'returns already verified error' do
        phone_user.verify_phone!

        post :resend, params: { phone: phone_user.phone }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.resend.already_verified'))
      end
    end

    context 'with non-existent phone number' do
      it 'returns user not found error' do
        post :resend, params: { phone: '+1234567890' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.resend.user_not_found'))
      end
    end

    context 'with missing phone parameter' do
      it 'returns user not found error' do
        post :resend, params: {}

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('sms_verifications.resend.user_not_found'))
      end
    end
  end
end
