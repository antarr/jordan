require 'rails_helper'

RSpec.describe SmsVerificationJob, type: :job do
  include ActiveJob::TestHelper

  let(:phone_user) { create(:user, :phone_user, :step_two) }

  describe '#perform' do
    before do
      phone_user.generate_sms_verification_code!
    end

    it 'sends SMS verification code' do
      expect(SmsService).to receive(:send_verification_code)
        .with(phone_user.phone, phone_user.sms_verification_code)
        .and_return(true)

      described_class.new.perform(phone_user)
    end

    it 'handles SMS sending failure gracefully' do
      expect(SmsService).to receive(:send_verification_code)
        .with(phone_user.phone, phone_user.sms_verification_code)
        .and_return(false)

      expect(Rails.logger).to receive(:error).with(/Failed to send SMS verification/)

      described_class.new.perform(phone_user)
    end

    it 'handles user without verification code' do
      phone_user.update!(sms_verification_code: nil)

      expect(SmsService).not_to receive(:send_verification_code)

      described_class.new.perform(phone_user)
    end

    it 'handles user without phone number' do
      phone_user.update_column(:phone, nil) # Use update_column to bypass validations

      expect(SmsService).not_to receive(:send_verification_code)

      described_class.new.perform(phone_user)
    end
  end

  describe 'job queuing' do
    it 'enqueues the job' do
      expect do
        described_class.perform_later(phone_user)
      end.to have_enqueued_job(described_class).with(phone_user)
    end

    it 'performs the job immediately in test' do
      phone_user.generate_sms_verification_code!

      perform_enqueued_jobs do
        expect(SmsService).to receive(:send_verification_code)
          .with(phone_user.phone, phone_user.sms_verification_code)
          .and_return(true)

        described_class.perform_later(phone_user)
      end
    end
  end
end
