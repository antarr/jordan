require 'rails_helper'

RSpec.describe EmailVerificationJob, type: :job do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  it 'sends email verification email' do
    expect(UserMailer).to receive(:email_verification).with(user).and_call_original
    EmailVerificationJob.perform_now(user)
  end

  it 'queues the job' do
    expect {
      EmailVerificationJob.perform_later(user)
    }.to have_enqueued_job(EmailVerificationJob).with(user)
  end
end