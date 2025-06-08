require 'rails_helper'

RSpec.describe 'Email Verification Flow', type: :feature do
  let(:test_user) do
    {
      email: 'capybara-verify@example.com',
      password: 'SecurePass123!'
    }
  end

  describe 'Email Verification on Registration' do
    it 'shows email verification notice after registration' do
      visit new_registration_path

      # Fill out registration form
      fill_in 'user[email]', with: test_user[:email]
      fill_in 'user[password]', with: test_user[:password]
      fill_in 'user[password_confirmation]', with: test_user[:password]

      # Submit form
      click_button 'Sign Up'

      # Should redirect to login with notice about email verification
      expect(current_path).to eq(new_session_path)
      expect(page).to have_content('Account created successfully! Please check your email to verify your account.')
    end

    it 'does not allow login before email verification' do
      # Create unverified user
      unverified_user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil
      )

      # Try to login
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should show unverified email error
      expect(page).to have_content('Please verify your email address before signing in')
      expect(current_path).to eq(new_session_path)
    end

    it 'allows login after email verification' do
      # Create unverified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil
      )

      # Visit verification link
      visit email_verification_path(token: user.email_verification_token)

      # Should show success message and redirect to dashboard (auto-signed in)
      expect(page).to have_content('Your email has been verified successfully!')
      expect(current_path).to eq(dashboard_path)
      
      # Should already be logged in
      expect(page).to have_content('Welcome to your dashboard')
    end

    it 'handles invalid verification token' do
      visit email_verification_path(token: 'invalid-token-123')

      # Should show error message
      expect(page).to have_content('Invalid or expired verification link')
      expect(current_path).to eq(new_session_path)
    end

    it 'handles already verified email' do
      # Create verified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: Time.current
      )

      # Try to use verification link
      visit email_verification_path(token: user.email_verification_token)

      # Should show success message (verifies again and signs in)
      expect(page).to have_content('Your email has been verified successfully!')
      expect(current_path).to eq(dashboard_path)
    end
  end

  describe 'Resend Verification Email' do
    let!(:unverified_user) do
      User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil
      )
    end

    it 'shows resend verification link on login failure' do
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should show unverified message with resend link
      expect(page).to have_content('Please verify your email address before signing in')
      expect(page).to have_link('Resend verification email')
    end

    it 'allows requesting new verification email' do
      visit new_email_verification_request_path

      # Check page elements
      expect(page).to have_css('h2', text: 'Resend Verification Email')
      expect(page).to have_field('email')
      expect(page).to have_button('Send Verification Email')

      # Submit email
      fill_in 'email', with: test_user[:email]
      click_button 'Send Verification Email'

      # Should show success message
      expect(page).to have_content('Verification email sent! Please check your inbox.')
      expect(current_path).to eq(new_session_path)
    end

    it 'handles resend for non-existent email' do
      visit new_email_verification_request_path

      fill_in 'email', with: 'nonexistent@example.com'
      click_button 'Send Verification Email'

      # Should show error message for non-existent email
      expect(page).to have_content('No account found with that email address')
    end

    it 'handles resend for already verified email' do
      # Create verified user
      verified_user = User.create!(
        email: 'verified@example.com',
        password: 'password123',
        email_verified_at: Time.current
      )

      visit new_email_verification_request_path
      fill_in 'email', with: 'verified@example.com'
      click_button 'Send Verification Email'

      # Should show already verified message
      expect(page).to have_content('Your email is already verified. You can sign in.')
    end
  end

  describe 'Email Verification Token Expiry' do
    it 'rejects expired verification tokens' do
      # Create user with expired token
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil
      )
      # Manually expire the token
      user.update_columns(email_verification_token_expires_at: 3.days.ago)

      # Try to use expired token
      visit email_verification_path(token: user.email_verification_token)

      # Should show expired message
      expect(page).to have_content('Invalid or expired verification link')
      expect(current_path).to eq(new_session_path)
    end
  end

  describe 'Dashboard Email Verification Status' do
    it 'shows unverified email warning on dashboard', skip: 'Sessions controller blocks unverified users' do
      # Create unverified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil
      )

      # Login normally - the sessions controller allows unverified users to sign in
      # but shows them a warning on the dashboard
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'
      
      # If blocked from dashboard due to verification, manually navigate
      visit dashboard_path
      
      # Check for verification warning
      expect(page).to have_css('[data-testid="email-verification-warning"]')
      within('[data-testid="email-verification-warning"]') do
        expect(page).to have_content('Your email address is not verified')
        expect(page).to have_link('Resend verification email')
      end
    end

    it 'does not show warning for verified users' do
      # Create verified user and login
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: Time.current
      )

      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      visit dashboard_path

      # Should not show unverified email warning
      expect(page).not_to have_css('[data-testid="email-verification-warning"]')
    end
  end

  describe 'Email Verification with ActionMailer' do
    it 'sends verification email on registration' do
      # Ensure test mode and inline job processing
      perform_enqueued_jobs do
        expect {
          visit new_registration_path
          fill_in 'user[email]', with: test_user[:email]
          fill_in 'user[password]', with: test_user[:password]
          fill_in 'user[password_confirmation]', with: test_user[:password]
          click_button 'Sign Up'
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(test_user[:email])
      expect(email.subject).to eq('Please verify your email address')
      expect(email.body.encoded).to include('email_verification')
    end

    it 'sends new verification email on resend request' do
      # Create unverified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil
      )

      perform_enqueued_jobs do
        expect {
          visit new_email_verification_request_path
          fill_in 'email', with: test_user[:email]
          click_button 'Send Verification Email'
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(test_user[:email])
      expect(email.subject).to eq('Please verify your email address')
    end
  end
end