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
      expect(page).to have_content('Please verify your email before logging in')
      expect(current_path).to eq(session_path)
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

      # Should show success message and redirect to login
      expect(page).to have_content('Email verified successfully')
      expect(current_path).to eq(new_session_path)

      # Now login should work
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should redirect to dashboard
      expect(current_path).to eq(dashboard_path)
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

      # Should show already verified message
      expect(page).to have_content('Email has already been verified')
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
      expect(page).to have_content('Please verify your email before logging in')
      expect(page).to have_link('Resend verification email')
    end

    it 'allows requesting new verification email' do
      visit new_email_verification_request_path

      # Check page elements
      expect(page).to have_css('h2', text: 'Resend Email Verification')
      expect(page).to have_field('email')
      expect(page).to have_button('Resend Verification Email')

      # Submit email
      fill_in 'email', with: test_user[:email]
      click_button 'Resend Verification Email'

      # Should show success message
      expect(page).to have_content('Verification email has been resent')
      expect(current_path).to eq(new_session_path)
    end

    it 'handles resend for non-existent email' do
      visit new_email_verification_request_path

      fill_in 'email', with: 'nonexistent@example.com'
      click_button 'Resend Verification Email'

      # Should show generic success message (security best practice)
      expect(page).to have_content('If an account exists with that email, a verification email has been sent')
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
      click_button 'Resend Verification Email'

      # Should show generic success message (security best practice)
      expect(page).to have_content('If an account exists with that email, a verification email has been sent')
    end
  end

  describe 'Email Verification Token Expiry' do
    it 'rejects expired verification tokens' do
      # Create user with expired token
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil,
        email_verification_sent_at: 3.days.ago
      )

      # Try to use expired token
      visit email_verification_path(token: user.email_verification_token)

      # Should show expired message
      expect(page).to have_content('Verification link has expired')
      expect(page).to have_link('Request a new verification email')
    end
  end

  describe 'Dashboard Email Verification Status' do
    it 'shows unverified email warning on dashboard' do
      # Create unverified user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: nil
      )

      # Force login (simulating admin override or testing scenario)
      page.driver.browser.rack_mock_session.cookie_jar[:user_id] = user.id
      visit dashboard_path

      # For this test to work properly, we need to update the dashboard view
      # to include the verification warning. This test assumes it exists.
      # If not implemented, this test will fail and remind us to add it.
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
      expect {
        visit new_registration_path
        fill_in 'user[email]', with: test_user[:email]
        fill_in 'user[password]', with: test_user[:password]
        fill_in 'user[password_confirmation]', with: test_user[:password]
        click_button 'Sign Up'
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

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

      expect {
        visit new_email_verification_request_path
        fill_in 'email', with: test_user[:email]
        click_button 'Resend Verification Email'
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(test_user[:email])
      expect(email.subject).to eq('Please verify your email address')
    end
  end
end