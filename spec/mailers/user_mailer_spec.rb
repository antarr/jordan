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

  describe '#account_locked' do
    let(:user) { create(:user, :complete_registration) }
    
    before do
      user.update!(locked_at: Time.current, locked_by_admin: false, auto_unlock_token: 'test_token_123')
    end

    let(:mail) { UserMailer.account_locked(user) }

    it 'renders the subject' do
      expect(mail.subject).to eq(I18n.t('user_mailer.account_locked.subject'))
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'contains the unlock token in body' do
      expect(mail.body.encoded).to include('test_token_123')
    end

    it 'contains account locked heading' do
      expect(mail.body.encoded).to include(I18n.t('user_mailer.account_locked.heading'))
    end

    it 'contains security alert warning' do
      expect(mail.body.encoded).to include(I18n.t('user_mailer.account_locked.warning_title'))
    end
  end
end