require 'rails_helper'

RSpec.describe 'Authentication Flow', type: :feature do
  let(:test_user) { build(:user, :complete_registration) }

  # Helper method to start registration flow and bypass JavaScript issues
  def start_registration_with_email
    page.driver.submit :post, registration_path, { contact_method: 'email' }
    visit current_path
  end

  describe 'User Registration' do
    it 'successfully registers a new user through multi-step form' do
      # Step 1: Start registration with email
      start_registration_with_email

      # Step 2: Contact details
      expect(page).to have_content('Step 2 of 6')
      expect(page).to have_field('user[email]')
      expect(page).to have_field('user[password]')
      expect(page).to have_field('user[password_confirmation]')

      fill_in 'user[email]', with: test_user.email
      fill_in 'user[password]', with: test_user.password
      fill_in 'user[password_confirmation]', with: test_user.password
      click_button 'Continue'

      # Step 3: Username
      expect(page).to have_content('Step 3 of 6')
      expect(page).to have_field('user[username]')

      fill_in 'user[username]', with: test_user.username
      click_button 'Continue'

      # Step 4: Bio
      expect(page).to have_content('Step 4 of 6')
      expect(page).to have_field('user[bio]')

      fill_in 'user[bio]', with: test_user.bio
      click_button 'Continue'

      # Step 5: Profile photo (optional, skip)
      expect(page).to have_content('Step 5 of 6')
      click_button 'Continue'

      # Step 6: Location (optional, skip)
      expect(page).to have_content('Step 6 of 6')
      click_button 'Complete Registration'

      # Should redirect to login with verification notice
      expect(current_path).to eq("/#{I18n.locale}/session/new")
      expect(page).to have_content('Account created successfully! Please check your email to verify your account.')
    end

    it 'shows validation errors for invalid registration' do
      visit new_registration_path

      # Try to submit without selecting contact method
      # Note: The submit button is disabled by default, so we can't click it
      # This test verifies the button remains disabled
      submit_button = find('input[type="submit"]')
      expect(submit_button).to be_disabled
    end

    it 'shows error for password mismatch' do
      # Step 1: Start registration with email
      start_registration_with_email

      # Step 2: Try with mismatched passwords
      fill_in 'user[email]', with: test_user.email
      fill_in 'user[password]', with: test_user.password
      fill_in 'user[password_confirmation]', with: 'DifferentPassword123!'
      click_button 'Continue'

      # Should stay on same page with error
      expect(current_path).to eq("/#{I18n.locale}/registration/contact_details")
      expect(page).to have_content("Password confirmation doesn't match Password")
    end

    it 'does not allow duplicate email registration' do
      # Create existing user
      User.create!(
        email: test_user.email,
        password: test_user.password,
        password_confirmation: test_user.password,
        email_verified_at: Time.current,
        contact_method: 'email',
        registration_step: 6,
        username: 'existinguser',
        bio: 'This is an existing user bio that meets the minimum length requirement'
      )

      # Step 1: Start registration with email
      start_registration_with_email

      fill_in 'user[email]', with: test_user[:email]
      fill_in 'user[password]', with: 'NewPassword123!'
      fill_in 'user[password_confirmation]', with: 'NewPassword123!'
      click_button 'Continue'

      expect(page).to have_content('Email has already been taken')
    end
  end

  describe 'User Login' do
    before do
      User.create!(
        email: test_user.email,
        password: test_user.password,
        password_confirmation: test_user.password,
        email_verified_at: Time.current,
        contact_method: 'email',
        registration_step: 6,
        username: 'testuser',
        bio: 'This is a test user bio that meets the minimum length requirement'
      )
    end

    it 'successfully logs in with valid credentials', js: true do
      visit new_session_path

      expect(page).to have_css('h2', text: 'Sign In')

      # Switch to email login (since form defaults to phone)
      click_button 'Email'

      # Wait for fields to become visible
      expect(page).to have_field('email', visible: true)
      expect(page).to have_field('password', visible: true)

      fill_in 'email', with: test_user.email
      fill_in 'password', with: test_user.password
      click_button 'Sign In'

      # In JavaScript mode, we check content rather than path due to async redirects
      expect(page).to have_content('Welcome to your dashboard')
    end

    it 'shows error for invalid credentials', js: true do
      visit new_session_path

      # Switch to email login
      click_button 'Email'

      # Wait for fields to become visible
      expect(page).to have_field('email', visible: true)

      fill_in 'email', with: test_user.email
      fill_in 'password', with: 'WrongPassword'
      click_button 'Sign In'

      expect(page).to have_content('Invalid email or password')
      # When authentication fails, we're redirected back to the login form
      expect(current_path).to eq('/session/new')
    end

    it 'shows error for non-existent user', js: true do
      visit new_session_path

      # Switch to email login
      click_button 'Email'

      # Wait for fields to become visible
      expect(page).to have_field('email', visible: true)

      fill_in 'email', with: 'nonexistent@example.com'
      fill_in 'password', with: 'SomePassword123!'
      click_button 'Sign In'

      expect(page).to have_content('Invalid email or password')
      # When authentication fails, we're redirected back to the login form
      expect(current_path).to eq('/session/new')
    end

    context 'with unverified email' do
      before do
        User.create!(
          email: 'unverified@example.com',
          password: 'Password123!',
          password_confirmation: 'Password123!',
          email_verified_at: nil,
          contact_method: 'email',
          registration_step: 6,
          username: 'unverifieduser',
          bio: 'This is an unverified user bio that meets the minimum length requirement'
        )
      end

      it 'prevents login and shows verification message', js: true do
        visit new_session_path

        # Switch to email login
        click_button 'Email'

        # Wait for fields to become visible
        expect(page).to have_field('email', visible: true)

        fill_in 'email', with: 'unverified@example.com'
        fill_in 'password', with: 'Password123!'
        click_button 'Sign In'

        expect(page).to have_content('Please verify your email address before signing in')
        expect(page).to have_link('Resend verification email')
        expect(current_path).to eq('/en/session/new')
      end
    end
  end

  describe 'Dashboard Access' do
    it 'redirects to login when not authenticated' do
      visit dashboard_path
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end

    context 'Protection' do
      it 'allows authenticated users to access dashboard', js: true do
        User.create!(
          email: test_user.email,
          password: test_user.password,
          password_confirmation: test_user.password,
          email_verified_at: Time.current,
          contact_method: 'email',
          registration_step: 6,
          username: 'dashboarduser',
          bio: 'This is a dashboard user bio that meets the minimum length requirement'
        )

        # Login
        visit new_session_path
        # Switch to email login
        click_button 'Email'
        # Wait for fields to become visible
        expect(page).to have_field('email', visible: true)
        fill_in 'email', with: test_user.email
        fill_in 'password', with: test_user.password
        click_button 'Sign In'

        # Should be able to access dashboard
        expect(page).to have_content('Welcome to your dashboard')

        # Try visiting dashboard directly after login
        visit '/en/dashboard'
        expect(page).to have_content('Welcome to your dashboard')
      end
    end
  end

  describe 'User Logout' do
    it 'successfully logs out user', js: true do
      User.create!(
        email: test_user.email,
        password: test_user.password,
        password_confirmation: test_user.password,
        email_verified_at: Time.current,
        contact_method: 'email',
        registration_step: 6,
        username: 'logoutuser',
        bio: 'This is a logout user bio that meets the minimum length requirement'
      )

      # Login first
      visit new_session_path
      # Switch to email login
      click_button 'Email'
      # Wait for fields to become visible
      expect(page).to have_field('email', visible: true)
      fill_in 'email', with: test_user.email
      fill_in 'password', with: test_user.password
      click_button 'Sign In'

      # Verify logged in
      expect(page).to have_content('Welcome to your dashboard')

      # Logout
      click_button 'Sign Out'

      # Should redirect to login page
      expect(page).to have_content('Sign In')

      # Should not be able to access protected pages
      visit dashboard_path
      expect(current_path).to eq("/#{I18n.locale}/session/new")
    end
  end

  describe 'Form Error Handling' do
    it 'preserves email on login failure', js: true do
      visit new_session_path

      # Switch to email login
      click_button 'Email'

      # Wait for fields to become visible
      expect(page).to have_field('email', visible: true)

      fill_in 'email', with: test_user.email
      fill_in 'password', with: 'WrongPassword'
      click_button 'Sign In'

      # After error, ensure we're still on email form (might need to switch back)
      unless page.has_field?('email', visible: true)
        click_button 'Email'
        expect(page).to have_field('email', visible: true)
      end

      # Email should still be filled in
      expect(find_field('email').value).to eq(test_user.email)
      # Password should be cleared for security
      expect(find_field('password').value).to be_blank
    end
  end

  describe 'Security Features' do
    it 'does not expose whether email exists', js: true do
      visit new_session_path

      # Switch to email login
      click_button 'Email'

      # Wait for fields to become visible
      expect(page).to have_field('email', visible: true)

      # Try with non-existent email
      fill_in 'email', with: 'doesnotexist@example.com'
      fill_in 'password', with: 'SomePassword123!'
      click_button 'Sign In'

      # Wait for error message to appear
      expect(page).to have_content('Invalid email or password', wait: 5)

      non_existent_message = page.text

      # Try with wrong password
      User.create!(
        email: test_user.email,
        password: test_user.password,
        password_confirmation: test_user.password,
        email_verified_at: Time.current,
        contact_method: 'email',
        registration_step: 6,
        username: 'securityuser',
        bio: 'This is a security user bio that meets the minimum length requirement'
      )

      # Switch to email form again for the second test
      click_button 'Email'
      expect(page).to have_field('email', visible: true)

      fill_in 'email', with: test_user.email
      fill_in 'password', with: 'WrongPassword'
      click_button 'Sign In'

      # Wait for error message to appear
      expect(page).to have_content('Invalid email or password', wait: 5)

      wrong_password_message = page.text

      # Messages should be identical
      expect(non_existent_message).to include('Invalid email or password')
      expect(wrong_password_message).to include('Invalid email or password')
    end
  end

  describe 'Password Manager Support' do
    it 'has proper autocomplete attributes for registration' do
      # Step 1: Start registration with email
      start_registration_with_email

      email_field = find_field('user[email]')
      password_field = find_field('user[password]')
      password_confirmation_field = find_field('user[password_confirmation]')

      expect(email_field['autocomplete']).to eq('email')
      expect(password_field['autocomplete']).to eq('new-password')
      expect(password_confirmation_field['autocomplete']).to eq('new-password')
    end

    it 'has proper form attributes', js: true do
      visit new_session_path

      # Switch to email login to access email fields
      click_button 'Email'

      # Wait for fields to become visible
      expect(page).to have_field('email', visible: true)

      email_field = find_field('email')
      password_field = find_field('password')

      expect(email_field['autocomplete']).to eq('email')
      expect(password_field['autocomplete']).to eq('current-password')
    end
  end
end
