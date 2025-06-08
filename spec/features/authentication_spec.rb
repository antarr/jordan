require 'rails_helper'

RSpec.describe 'Authentication Flow', type: :feature do
  let(:test_user) do
    {
      email: 'capybara-test@example.com',
      password: 'SecurePass123!'
    }
  end

  describe 'User Registration' do
    it 'successfully registers a new user' do
      visit new_registration_path

      # Check page elements
      expect(page).to have_css('h2', text: 'Sign Up')
      expect(page).to have_field('user[email]')
      expect(page).to have_field('user[password]')
      expect(page).to have_field('user[password_confirmation]')
      expect(page).to have_button('Sign Up')

      # Fill out registration form
      fill_in 'user[email]', with: test_user[:email]
      fill_in 'user[password]', with: test_user[:password]
      fill_in 'user[password_confirmation]', with: test_user[:password]

      # Submit form
      click_button 'Sign Up'

      # Should redirect to login with verification notice
      expect(current_path).to eq(new_session_path)
      expect(page).to have_content('Account created successfully! Please check your email to verify your account.')
    end

    it 'shows validation errors for invalid registration' do
      visit new_registration_path

      # Try to submit with empty fields
      click_button 'Sign Up'

      # Should stay on registration page
      expect(current_path).to eq(registration_path)
      expect(page).to have_content("can't be blank")
    end

    it 'shows error for password mismatch' do
      visit new_registration_path

      fill_in 'user[email]', with: test_user[:email]
      fill_in 'user[password]', with: test_user[:password]
      fill_in 'user[password_confirmation]', with: 'different-password'

      click_button 'Sign Up'

      # Should show validation error
      expect(page).to have_content("doesn't match Password")
    end

    it 'does not allow duplicate email registration' do
      # First, create a user
      User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: Time.current
      )

      # Try to register with same email
      visit new_registration_path
      fill_in 'user[email]', with: test_user[:email]
      fill_in 'user[password]', with: 'different-password'
      fill_in 'user[password_confirmation]', with: 'different-password'
      click_button 'Sign Up'

      # Should show validation error
      expect(page).to have_content('has already been taken')
      expect(current_path).to eq(registration_path)
    end
  end

  describe 'User Login' do
    let!(:verified_user) do
      User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: Time.current
      )
    end

    it 'successfully logs in with valid credentials' do
      visit new_session_path

      # Check page elements
      expect(page).to have_css('h2', text: 'Sign In')
      expect(page).to have_field('email')
      expect(page).to have_field('password')
      expect(page).to have_button('Sign In')

      # Login
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should redirect to dashboard
      expect(current_path).to eq(dashboard_path)
      expect(page).to have_content('Welcome to your dashboard')

      # Check navigation shows user email
      expect(page).to have_content(test_user[:email])
      expect(page).to have_button('Sign Out')
    end

    it 'shows error for invalid credentials' do
      visit new_session_path

      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: 'wrong-password'
      click_button 'Sign In'

      # Should show error message
      expect(page).to have_content('Invalid email or password')
      expect(current_path).to eq(session_path)
    end

    it 'shows error for non-existent user' do
      visit new_session_path

      fill_in 'email', with: 'nonexistent@example.com'
      fill_in 'password', with: 'any-password'
      click_button 'Sign In'

      # Should show error message
      expect(page).to have_content('Invalid email or password')
      expect(current_path).to eq(session_path)
    end

    context 'with unverified email' do
      let!(:unverified_user) do
        User.create!(
          email: 'unverified@example.com',
          password: test_user[:password],
          email_verified_at: nil
        )
      end

      it 'prevents login and shows verification message' do
        visit new_session_path

        fill_in 'email', with: 'unverified@example.com'
        fill_in 'password', with: test_user[:password]
        click_button 'Sign In'

        # Should show unverified message
        expect(page).to have_content('Please verify your email address before signing in')
        expect(page).to have_link('Resend verification email')
      end
    end
  end

  describe 'Dashboard Access Protection' do
    it 'redirects unauthenticated users to login' do
      visit dashboard_path

      # Should redirect to login page
      expect(current_path).to eq(new_session_path)
      # Check for login form presence instead of specific message
      expect(page).to have_field('email')
      expect(page).to have_field('password')
    end

    it 'allows authenticated users to access dashboard' do
      # Create and login user
      user = User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: Time.current
      )

      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'

      # Should be on dashboard
      expect(current_path).to eq(dashboard_path)
      expect(page).to have_content('Welcome to your dashboard')
    end
  end

  describe 'User Logout' do
    let!(:user) do
      User.create!(
        email: test_user[:email],
        password: test_user[:password],
        email_verified_at: Time.current
      )
    end

    before do
      # Login user
      visit new_session_path
      fill_in 'email', with: test_user[:email]
      fill_in 'password', with: test_user[:password]
      click_button 'Sign In'
    end

    it 'successfully logs out user' do
      # Should be on dashboard
      expect(current_path).to eq(dashboard_path)

      # Click logout
      click_button 'Sign Out'

      # Should redirect away from dashboard
      expect(current_path).not_to eq(dashboard_path)

      # Try to access dashboard - should redirect to login
      visit dashboard_path
      expect(current_path).to eq(new_session_path)
    end
  end

  describe 'Navigation Links' do
    it 'navigates between registration and login pages' do
      visit new_registration_path

      # Click "Sign in" link
      click_link 'Sign in'
      expect(current_path).to eq(new_session_path)
      expect(page).to have_css('h2', text: 'Sign In')

      # Click "Sign up" link
      click_link 'Sign up'
      expect(current_path).to eq(new_registration_path)
      expect(page).to have_css('h2', text: 'Sign Up')
    end
  end

  describe 'Password Manager Support' do
    it 'has proper autocomplete attributes for registration' do
      visit new_registration_path

      email_field = find_field('user[email]')
      password_field = find_field('user[password]')
      confirmation_field = find_field('user[password_confirmation]')

      expect(email_field['autocomplete']).to eq('email')
      expect(password_field['autocomplete']).to eq('new-password')
      expect(confirmation_field['autocomplete']).to eq('new-password')
    end

    it 'has proper form attributes' do
      visit new_registration_path

      form = find('form')
      expect(form['autocomplete']).to eq('on')
    end
  end
end