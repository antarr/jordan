require 'rails_helper'

RSpec.describe 'Email Verification Flow', type: :feature do
  let(:test_user) do
    {
      email: 'capybara-verify@example.com',
      password: 'SecurePass123!',
      username: 'verifyuser',
      bio: 'This is my test bio that is at least 25 characters long for validation purposes.'
    }
  end

  # Helper method to start registration flow and bypass JavaScript issues
  def start_registration_with_email
    page.driver.submit :post, registration_path, { contact_method: 'email' }
    visit current_path
  end

  describe 'Email Verification on Registration' do
    it 'shows email verification notice after registration' do
      # Step 1: Start registration with email
      start_registration_with_email

      # Step 2: Contact details
      fill_in 'user[email]', with: test_user[:email]
      fill_in 'user[password]', with: test_user[:password]
      fill_in 'user[password_confirmation]', with: test_user[:password]
      click_button 'Continue'

      # Step 3: Username
      fill_in 'user[username]', with: test_user[:username]
      click_button 'Continue'

      # Step 4: Bio
      fill_in 'user[bio]', with: test_user[:bio]
      click_button 'Continue'

      # Step 5: Profile photo (skip)
      click_button 'Complete Registration'

      # Should redirect to login with notice about email verification
      expect(current_path).to eq("/#{I18n.locale}/session/new")
      expect(page).to have_content('Account created successfully! Please check your email to verify your account.')
    end

    it 'does not allow login before email verification' do
      # Create unverified user
      unverified_user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: nil,
        contact_method: 'email',
        registration_step: 5,
        username: 'unverified',
        bio: 'This is an unverified user bio that meets the minimum length requirement'
      )

      # Try to login
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should show unverified email error
      expect(page).to have_content('Please verify your email address before signing in')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end

    it 'allows login after email verification' do
      # Create unverified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: nil,
        contact_method: 'email',
        registration_step: 5,
        username: 'toverify',
        bio: 'This is a user bio that meets the minimum length requirement to verify'
      )

      # Visit verification link
      visit email_verification_path(token: user.email_verification_token)

      # Should show success message and redirect to dashboard (auto-signed in)
      expect(page).to have_content('Your email has been verified successfully!')
      expect(current_path).to eq("/#{I18n.locale}/dashboard")
      
      # Should already be logged in
      expect(page).to have_content('Welcome to your dashboard')
    end

    it 'handles invalid verification token' do
      visit email_verification_path(token: 'invalid-token-123')

      # Should show error message
      expect(page).to have_content('Invalid or expired verification link')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end

    it 'handles already verified email' do
      # Create verified user with token still present (edge case)
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: Time.current,
        email_verification_token: SecureRandom.urlsafe_base64(32),
        email_verification_token_expires_at: 24.hours.from_now,
        contact_method: 'email',
        registration_step: 5,
        username: 'alreadyverified',
        bio: 'This is an already verified user bio that meets the minimum length requirement'
      )

      # Try to use verification link
      visit email_verification_path(token: user.email_verification_token)

      # Should show success message (verifies again and signs in)
      expect(page).to have_content('Your email has been verified successfully!')
      expect(current_path).to eq("/#{I18n.locale}/dashboard")
    end
  end

  describe 'Resend Verification Email' do
    let!(:unverified_user) do
      User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: nil,
        contact_method: 'email',
        registration_step: 5,
        username: 'resenduser',
        bio: 'This is a resend user bio that meets the minimum length requirement'
      )
    end

    it 'shows resend verification link on login failure' do
      # Try to login with unverified email
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should show resend link
      expect(page).to have_content('Please verify your email address before signing in')
      expect(page).to have_link('Resend verification email')
    end

    it 'allows requesting new verification email' do
      # Visit login page
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Click resend link
      click_link 'Resend verification email'

      # Should be on resend page
      expect(current_path).to eq("/#{I18n.locale}/resend_verification/new")
      expect(page).to have_field('email')

      # Submit resend request
      fill_in 'email', with: test_user[:email]
      click_button 'Send Verification Email'

      # Should show success message
      expect(page).to have_content('If an account exists with that email, we have sent a new verification link')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end

    it 'handles resend for non-existent email' do
      visit new_email_verification_request_path

      fill_in 'email', with: 'nonexistent@example.com'
      click_button 'Send Verification Email'

      # Should show same success message for security (don't expose if email exists)
      expect(page).to have_content('If an account exists with that email, we have sent a new verification link')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end

    it 'handles resend for already verified email' do
      # Create verified user
      verified_user = User.create!(
        email: 'verified@example.com',
        password: 'Password123!',
        password_confirmation: 'Password123!',
        email_verified_at: Time.current,
        contact_method: 'email',
        registration_step: 5,
        username: 'verifiedresend',
        bio: 'This is a verified resend user bio that meets the minimum length requirement'
      )

      visit new_email_verification_request_path

      fill_in 'email', with: verified_user.email
      click_button 'Send Verification Email'

      # Should show same success message for security
      expect(page).to have_content('If an account exists with that email, we have sent a new verification link')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end
  end

  describe 'Email Verification Token Expiry' do
    it 'rejects expired verification tokens' do
      # Create user with expired token
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: nil,
        contact_method: 'email',
        registration_step: 5,
        username: 'expiredtoken',
        bio: 'This is an expired token user bio that meets the minimum length requirement'
      )

      # Manually expire the token
      user.update!(email_verification_token_expires_at: 25.hours.ago)

      # Try to use expired token
      visit email_verification_path(token: user.email_verification_token)

      # Should show error message
      expect(page).to have_content('Invalid or expired verification link')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end
  end

  describe 'Email Change Verification' do
    # Note: If email change feature is implemented, tests would go here
    # For now, users can't change email after registration
  end

  describe 'Verification Link Security' do
    it 'requires token to access verification page' do
      visit email_verification_path(token: 'invalid-empty-token')

      expect(page).to have_content('Invalid or expired verification link')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end

    it 'is case-sensitive for tokens' do
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: nil,
        contact_method: 'email',
        registration_step: 5,
        username: 'casetest',
        bio: 'This is a case test user bio that meets the minimum length requirement'
      )

      # Try with wrong case
      visit email_verification_path(token: user.email_verification_token.upcase)

      expect(page).to have_content('Invalid or expired verification link')
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end
  end

  describe 'Dashboard Email Verification Status' do
    it 'does not show warning for verified users' do
      # Create verified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: Time.current,
        contact_method: 'email',
        registration_step: 5,
        username: 'dashverified',
        bio: 'This is a dashboard verified user bio that meets the minimum length requirement'
      )

      # Login
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should not show any verification warning
      expect(page).not_to have_content('verify your email')
      expect(page).not_to have_content('Verification required')
    end
  end

  describe 'Email Verification with ActionMailer' do
    include ActiveJob::TestHelper

    it 'sends verification email on registration' do
      perform_enqueued_jobs do
        expect {
          # Step 1: Start registration with email
          start_registration_with_email
          
          # Step 2: Contact details
          fill_in 'user[email]', with: test_user[:email]
          fill_in 'user[password]', with: test_user[:password]
          fill_in 'user[password_confirmation]', with: test_user[:password]
          click_button 'Continue'
          
          # Step 3: Username
          fill_in 'user[username]', with: test_user[:username]
          click_button 'Continue'
          
          # Step 4: Bio
          fill_in 'user[bio]', with: test_user[:bio]
          click_button 'Continue'
          
          # Step 5: Profile photo (skip)
          click_button 'Complete Registration'
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      # Check the email was sent to the right person
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(test_user[:email])
      expect(email.subject).to match(/verify your email/i)
    end

    it 'sends new verification email on resend request' do
      # Create unverified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        password_confirmation: test_user[:password],
        email_verified_at: nil,
        contact_method: 'email',
        registration_step: 5,
        username: 'resendemail',
        bio: 'This is a resend email user bio that meets the minimum length requirement'
      )

      perform_enqueued_jobs do
        expect {
          visit new_email_verification_request_path
          fill_in 'email', with: test_user[:email]
          click_button 'Send Verification Email'
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end