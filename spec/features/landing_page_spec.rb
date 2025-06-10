require 'rails_helper'

RSpec.describe 'Landing Page', type: :feature do
  describe 'Navigation' do
    it 'has a dashboard link that redirects to login when not authenticated' do
      visit coming_soon_path
      
      expect(page).to have_link('Dashboard')
      
      click_link 'Dashboard'
      
      # Should redirect to login page since user is not authenticated
      expect(current_path).to end_with('/session/new')
      expect(page).to have_content('Sign In')
    end
    
    it 'has a sign in link' do
      visit coming_soon_path
      
      expect(page).to have_link('Sign In')
      
      click_link 'Sign In'
      
      expect(current_path).to end_with('/session/new')
      expect(page).to have_content('Sign In')
    end
    
    it 'displays the Ragged brand' do
      visit coming_soon_path
      
      expect(page).to have_content('Ragged')
      expect(page).to have_content('Something amazing is coming')
    end
  end
  
  describe 'Dashboard access for authenticated users', js: true do
    let(:user) do
      User.create!(
        email: 'test@example.com',
        password: 'Password123!',
        password_confirmation: 'Password123!',
        email_verified_at: Time.current,
        contact_method: 'email',
        registration_step: 6,
        username: 'testuser',
        bio: 'This is a test user bio that meets the minimum length requirement'
      )
    end
    
    it 'allows authenticated users to access dashboard from landing page' do
      # First login
      visit new_session_path
      click_button 'Email'
      expect(page).to have_field('email', visible: true)
      fill_in 'email', with: user.email
      fill_in 'password', with: user.password
      click_button 'Sign In'
      
      expect(page).to have_content('Welcome to your dashboard')
      
      # Now visit landing page and click dashboard
      visit coming_soon_path
      click_link 'Dashboard'
      
      # Should go directly to dashboard since user is authenticated
      expect(page).to have_content('Welcome to your dashboard')
    end
  end
end