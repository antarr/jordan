require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe '#email_verification' do
    let(:user) { create(:user, :email_user, :step_two, :unverified) }
    let(:mail) { UserMailer.email_verification(user) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Please verify your email address')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'includes verification link in body' do
      expect(mail.body.encoded).to include(user.email_verification_token)
      expect(mail.body.encoded).to include('email_verification')
    end

    it 'includes user email in body' do
      expect(mail.body.encoded).to include('Verify Email Address')
    end

    it 'includes the verification URL' do
      verification_url = "http://localhost:3000/email_verification/#{user.email_verification_token}"
      expect(mail.body.encoded).to include(verification_url)
    end
  end
end