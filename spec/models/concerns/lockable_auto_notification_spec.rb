require 'rails_helper'

RSpec.describe 'Lockable auto-lock notifications', type: :model do
  let(:user) { create(:user, :complete_registration) }

  describe 'when account gets auto-locked' do
    it 'sends email notification' do
      # Make 4 failed attempts (one away from locking)
      4.times { user.record_failed_login! }
      
      expect {
        # The 5th attempt should lock the account and send email
        user.record_failed_login!
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      
      # Verify the email was sent to the correct address
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(user.email)
      expect(email.subject).to eq(I18n.t('user_mailer.account_locked.subject'))
    end

    it 'generates unlock token when account is locked' do
      # Make 5 failed attempts to lock the account
      5.times { user.record_failed_login! }
      
      user.reload
      expect(user.locked?).to be true
      expect(user.auto_locked?).to be true
      expect(user.auto_unlock_token).to be_present
    end

    it 'does not send email if user has no email address' do
      # Create a phone-only user
      phone_user = create(:user, :complete_registration, email: nil, contact_method: 'phone', phone: '+1234567890')
      
      expect {
        5.times { phone_user.record_failed_login! }
      }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'includes unlock link in the email' do
      5.times { user.record_failed_login! }
      
      email = ActionMailer::Base.deliveries.last
      email_body = email.body.parts.empty? ? email.body.to_s : email.body.parts.first.body.to_s
      expect(email_body).to include(user.reload.auto_unlock_token)
    end
  end

  describe 'when account is already locked' do
    before do
      user.lock_account!
    end

    it 'does not send additional emails for failed attempts' do
      expect {
        user.record_failed_login!
      }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end

  describe 'email content' do
    before do
      5.times { user.record_failed_login! }
      @email = ActionMailer::Base.deliveries.last
      @email_body = @email.body.parts.empty? ? @email.body.to_s : @email.body.parts.first.body.to_s
    end

    it 'contains security warning' do
      expect(@email_body).to include(I18n.t('user_mailer.account_locked.warning_title'))
    end

    it 'contains unlock link' do
      expect(@email_body).to include('unlock-account')
    end

    it 'contains explanation' do
      expect(@email_body).to include(I18n.t('user_mailer.account_locked.explanation'))
    end

    it 'contains security tip' do
      expect(@email_body).to include(I18n.t('user_mailer.account_locked.security_tip'))
    end
  end
end