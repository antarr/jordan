require 'rails_helper'

RSpec.feature 'Login Form Structure', :js, type: :feature do
  scenario 'Login page loads with correct initial state' do
    visit new_session_path

    # Check page loads successfully
    expect(page).to have_content('Sign In')

    # Check both tab buttons exist
    expect(page).to have_button('Email')
    expect(page).to have_button('Phone')

    # Check both forms exist with correct data attributes (including hidden ones)
    expect(page).to have_selector('[data-login-toggle-target="emailForm"]', visible: :all)
    expect(page).to have_selector('[data-login-toggle-target="phoneForm"]', visible: :all)

    # Wait for Stimulus controller to initialize
    expect(page).to have_selector('[data-controller="login-toggle"]')

    # Check initial visibility - email form should be hidden, phone form visible
    email_form = page.find('[data-login-toggle-target="emailForm"]', visible: :all)
    phone_form = page.find('[data-login-toggle-target="phoneForm"]', visible: :all)

    expect(email_form).not_to be_visible
    expect(phone_form).to be_visible

    # Check phone form has expected fields
    within('[data-login-toggle-target="phoneForm"]') do
      expect(page).to have_field('phone')
      expect(page).to have_field('sms_code')
      expect(page).to have_field('password')
      expect(page).to have_field('login_type', type: 'hidden', with: 'phone')
    end
  end

  scenario 'Phone form is not hidden initially' do
    visit new_session_path

    # Wait for Stimulus controller to initialize
    expect(page).to have_selector('[data-controller="login-toggle"]')

    # Phone form should be visible
    phone_form = find('[data-login-toggle-target="phoneForm"]', visible: :all)
    expect(phone_form).to be_visible

    # Email form should not be visible
    email_form = find('[data-login-toggle-target="emailForm"]', visible: :all)
    expect(email_form).not_to be_visible
  end
end
