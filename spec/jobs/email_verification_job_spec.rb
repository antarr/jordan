require 'rails_helper'

RSpec.describe EmailVerificationJob, type: :job do
  let(:user) { create(:user, :email_user, :step_two) }

  it 'sends email verification email' do
    expect(UserMailer).to receive(:email_verification).with(user).and_call_original
    described_class.perform_now(user)
  end

  it 'queues the job' do
    expect do
      described_class.perform_later(user)
    end.to have_enqueued_job(described_class).with(user)
  end
end
