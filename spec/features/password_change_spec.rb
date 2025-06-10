require 'rails_helper'

RSpec.describe 'Password Change', type: :feature do
  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'CurrentPassword123!',
      password_confirmation: 'CurrentPassword123!',
      email_verified_at: Time.current,
      contact_method: 'email',
      registration_step: 6,
      username: 'testuser',
      bio: 'This is a test user bio that meets the minimum length requirement'
    )
  end

  before do
    # Login as the user
    visit new_session_path
    click_button 'Email'
    expect(page).to have_field('email', visible: true)
    fill_in 'email', with: user.email
    fill_in 'password', with: 'CurrentPassword123!'
    click_button 'Sign In'
    expect(page).to have_content('Welcome to your dashboard')
    
    # Navigate to profile settings
    visit edit_profile_path
  end

  describe 'Password Change Modal', js: true do
    it 'opens and closes the password change modal' do
      # Check that modal is initially hidden
      expect(page).to have_css('[data-password-change-target="modal"]', visible: false)
      
      # Click Change Password button
      click_button 'Change Password'
      
      # Modal should be visible
      expect(page).to have_css('[data-password-change-target="modal"]', visible: true)
      expect(page).to have_content('Change Password')
      expect(page).to have_field('Current Password')
      expect(page).to have_field('New Password')
      expect(page).to have_field('Confirm New Password')
      
      # Close modal with Cancel button
      within('[data-password-change-target="modal"]') do
        click_button 'Cancel'
      end
      
      # Modal should be hidden again
      expect(page).to have_css('[data-password-change-target="modal"]', visible: false)
    end
    
    it 'closes modal with X button' do
      click_button 'Change Password'
      expect(page).to have_css('[data-password-change-target="modal"]', visible: true)
      
      # Close with X button (find the one inside the modal header)
      within('[data-password-change-target="modal"]') do
        find('button[data-action="click->password-change#hideModal"]', match: :first).click
      end
      
      expect(page).to have_css('[data-password-change-target="modal"]', visible: false)
    end
  end

  describe 'Password Change Process', js: true do
    it 'successfully changes password with valid inputs' do
      click_button 'Change Password'
      
      within('[data-password-change-target="modal"]') do
        fill_in 'Current Password', with: 'CurrentPassword123!'
        fill_in 'New Password', with: 'NewPassword123!'
        fill_in 'Confirm New Password', with: 'NewPassword123!'
        
        click_button 'Change Password'
      end
      
      # Should redirect back to profile page with success message
      expect(current_path).to end_with('/profile/edit')
      expect(page).to have_content('Password changed successfully')
    end
    
    it 'shows error for incorrect current password' do
      click_button 'Change Password'
      
      within('[data-password-change-target="modal"]') do
        fill_in 'Current Password', with: 'WrongPassword123!'
        fill_in 'New Password', with: 'NewPassword123!'
        fill_in 'Confirm New Password', with: 'NewPassword123!'
        
        click_button 'Change Password'
      end
      
      # Should show error for incorrect current password
      expect(page).to have_content('Current password is incorrect')
    end
    
    it 'shows error for password confirmation mismatch' do
      click_button 'Change Password'
      
      within('[data-password-change-target="modal"]') do
        fill_in 'Current Password', with: 'CurrentPassword123!'
        fill_in 'New Password', with: 'NewPassword123!'
        fill_in 'Confirm New Password', with: 'DifferentPassword123!'
        
        click_button 'Change Password'
      end
      
      # Should show validation error (could be client-side or server-side)
      expect(page).to have_content("Passwords don't match").or(have_content("Password confirmation doesn't match Password"))
    end
    
    it 'requires minimum password length' do
      click_button 'Change Password'
      
      within('[data-password-change-target="modal"]') do
        fill_in 'Current Password', with: 'CurrentPassword123!'
        fill_in 'New Password', with: 'short'
        fill_in 'Confirm New Password', with: 'short'
        
        click_button 'Change Password'
      end
      
      # Should show validation error for short password (could be client-side or server-side)
      expect(page).to have_content('Password must be at least 8 characters').or(have_content('Password is too short'))
    end
  end


  describe 'After Password Change' do
    it 'allows login with new password after change', js: true do
      # Change password
      click_button 'Change Password'
      
      within('[data-password-change-target="modal"]') do
        fill_in 'Current Password', with: 'CurrentPassword123!'
        fill_in 'New Password', with: 'NewPassword123!'
        fill_in 'Confirm New Password', with: 'NewPassword123!'
        
        click_button 'Change Password'
      end
      
      expect(page).to have_content('Password changed successfully')
      
      # Logout
      click_button 'Sign Out'
      
      # Try to login with new password
      visit new_session_path
      click_button 'Email'
      expect(page).to have_field('email', visible: true)
      fill_in 'email', with: user.email
      fill_in 'password', with: 'NewPassword123!'
      click_button 'Sign In'
      
      # Should be able to login with new password
      expect(page).to have_content('Welcome to your dashboard')
    end
  end
end