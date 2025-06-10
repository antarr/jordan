require 'rails_helper'

RSpec.describe 'Profile Settings', type: :feature do
  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      email_verified_at: Time.current,
      contact_method: 'email',
      registration_step: 6,
      username: 'testuser',
      bio: 'This is a test user bio that meets the minimum length requirement for the application'
    )
  end

  before do
    # Login as the user
    visit new_session_path
    click_button 'Email'
    expect(page).to have_field('email', visible: true)

    within('[data-login-toggle-target="emailForm"]') do
      fill_in 'email', with: user.email
      fill_in 'password', with: user.password
      click_button 'Sign In'
    end

    expect(page).to have_content('Welcome to your dashboard')
  end

  describe 'Profile Settings Page', js: true do
    it 'displays the modern profile settings interface' do
      visit edit_profile_path

      # Check page structure
      expect(page).to have_content('Account Settings')
      expect(page).to have_content('Manage your account information and preferences')

      # Check card sections
      expect(page).to have_content('Profile Information')
      expect(page).to have_content('Location')
      expect(page).to have_content('Security')

      # Check navigation
      expect(page).to have_link('Back to Dashboard')
    end

    it 'allows updating profile information' do
      visit edit_profile_path

      # Update username and bio
      fill_in 'Username', with: 'newusername'
      fill_in 'Bio', with: 'This is my updated bio information that provides more details about myself'

      click_button 'Save Changes'

      # Should redirect back to profile edit page with success message
      expect(current_path).to end_with('/profile/edit')
      expect(page).to have_field('Username', with: 'newusername')
      expect(page).to have_field('Bio',
                                 with: 'This is my updated bio information that provides more details about myself')
    end

    it 'displays email verification warning for unverified users' do
      # Create unverified user
      unverified_user = User.create!(
        email: 'unverified@example.com',
        password: 'Password123!',
        password_confirmation: 'Password123!',
        email_verified_at: nil,
        contact_method: 'email',
        registration_step: 6,
        username: 'unverified',
        bio: 'This is an unverified user bio that meets the minimum length requirement'
      )

      # Login as unverified user - this should work for profile editing
      # but show verification warning
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(unverified_user)

      visit edit_profile_path

      expect(page).to have_content('Email not verified')
      expect(page).to have_link('Resend verification')
    end

    it 'shows profile photo upload section' do
      visit edit_profile_path

      expect(page).to have_content('Profile Photo')
      expect(page).to have_content('Upload Photo')
      expect(page).to have_content('JPG, PNG, or GIF up to 5MB')
    end

    it 'shows location settings' do
      visit edit_profile_path

      expect(page).to have_content('Location')
      expect(page).to have_field('Location Name')
      expect(page).to have_field('Keep my location private')
      expect(page).to have_content('your location won\'t be visible to other users')
    end

    it 'shows security section with placeholder features' do
      visit edit_profile_path

      expect(page).to have_content('Security')
      expect(page).to have_content('Password')
      expect(page).to have_button('Change Password')
      expect(page).to have_content('Two-Factor Authentication')
      expect(page).to have_button('Enable')
    end

    it 'has cancel and save action buttons' do
      visit edit_profile_path

      expect(page).to have_link('Cancel')
      expect(page).to have_button('Save Changes')
      expect(page).to have_button('Delete Account')
    end

    it 'allows navigation back to dashboard' do
      visit edit_profile_path

      expect(page).to have_link('Back to Dashboard')
      click_link 'Back to Dashboard'

      # Should navigate to dashboard
      expect(page).to have_content('Welcome to your dashboard')
    end
  end

  describe 'Responsive Design' do
    it 'adapts to different screen sizes' do
      visit edit_profile_path

      # Check that the layout uses responsive classes
      expect(page).to have_css('.max-w-4xl') # Container max width
      expect(page).to have_css('.md\\:grid-cols-2') # Grid responsiveness
      expect(page).to have_css('.sm\\:px-6') # Responsive padding
    end
  end
end
