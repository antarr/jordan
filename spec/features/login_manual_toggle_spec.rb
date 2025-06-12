require 'rails_helper'

RSpec.feature 'Login Manual Toggle Test', :js, type: :feature do
  scenario 'Manual check of form visibility' do
    visit new_session_path

    # Wait for Stimulus controller to initialize and set up the initial state
    expect(page).to have_selector('[data-controller="login-toggle"]')

    # Get form elements
    email_form = page.find('[data-login-toggle-target="emailForm"]', visible: :all)
    phone_form = page.find('[data-login-toggle-target="phoneForm"]', visible: :all)

    # Check initial state - email form should be hidden
    # The Stimulus controller sets display: none on the email form during initialization
    expect(email_form).not_to be_visible

    # Phone form should be visible by default
    expect(phone_form).to be_visible

    # Verify the forms have the expected content
    within(phone_form) do
      expect(page).to have_field('phone')
      expect(page).to have_field('password')
    end

    # Email form should exist but not be visible
    within(email_form) do
      expect(page).to have_field('email', visible: false)
      expect(page).to have_field('password', visible: false)
    end
  end
end
