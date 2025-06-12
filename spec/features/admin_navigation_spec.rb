require 'rails_helper'

RSpec.feature 'Admin Navigation', :js, type: :feature do
  let(:admin_role) { create(:role, name: 'admin') }
  let(:admin_user) do
    create(:user,
           email: 'admin@example.com',
           password: 'TestPassword123!',
           password_confirmation: 'TestPassword123!',
           role: admin_role,
           registration_step: 6,
           email_verified_at: Time.current)
  end

  before do
    # Create the admin user
    admin_user

    # Sign in as admin user
    visit new_session_path

    # Switch to email login form
    click_button 'Email'

    # Wait for email form to become visible
    expect(page).to have_css('[data-login-toggle-target="emailForm"]', visible: true, wait: 5)

    # Fill in the email login form
    within('[data-login-toggle-target="emailForm"]') do
      fill_in 'email', with: 'admin@example.com'
      fill_in 'password', with: 'TestPassword123!'
      click_button 'Sign In'
    end

    # Should be redirected to dashboard
    expect(page).to have_current_path('/en/dashboard')
  end

  scenario 'Admin can navigate to role management' do
    # Check if we're on the dashboard
    expect(page).to have_content('Welcome to your dashboard')

    # Click on the settings dropdown button
    find('[data-hello-target="button"]').click

    # Wait for dropdown to appear
    expect(page).to have_css('[data-hello-target="menu"]:not(.hidden)', wait: 5)

    # Click on "Manage Roles" link
    within('[data-hello-target="menu"]') do
      click_link 'Manage Roles'
    end

    # Should navigate to roles index
    expect(page).to have_current_path('/en/admin/roles')
    expect(page).to have_content('Roles')
  end

  scenario 'Admin can navigate to user management' do
    # Click on the settings dropdown button
    find('[data-hello-target="button"]').click

    # Wait for dropdown to appear
    expect(page).to have_css('[data-hello-target="menu"]:not(.hidden)', wait: 5)

    # Click on "Manage Users" link
    within('[data-hello-target="menu"]') do
      click_link 'Manage Users'
    end

    # Should navigate to users index
    expect(page).to have_current_path('/en/admin/users')
    expect(page).to have_content('Users')
  end

  scenario 'Admin can navigate to profile settings' do
    # Click on the settings dropdown button
    find('[data-hello-target="button"]').click

    # Wait for dropdown to appear
    expect(page).to have_css('[data-hello-target="menu"]:not(.hidden)', wait: 5)

    # Click on "Profile Settings" link
    within('[data-hello-target="menu"]') do
      click_link 'Profile Settings'
    end

    # Should navigate to profile edit
    expect(page).to have_current_path('/en/profile/edit')
    expect(page).to have_content('Account Settings')
  end
end
