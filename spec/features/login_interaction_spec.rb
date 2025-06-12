require 'rails_helper'

RSpec.feature 'Login Form Interaction', :js, type: :feature do
  scenario 'Can interact with phone form by default' do
    visit new_session_path

    # Wait for Stimulus controller to initialize
    expect(page).to have_selector('[data-controller="login-toggle"]')

    # Should be able to interact with phone form fields
    expect(page).to have_field('phone')
    fill_in 'phone', with: '+1234567890'

    # Email form should exist but not be visible
    expect(page).to have_field('email', visible: false)

    # Email field should not be interactable when the form is hidden
    email_form = page.find('[data-login-toggle-target="emailForm"]', visible: :all)
    expect(email_form).not_to be_visible
  end

  scenario 'Phone form is the default selection' do
    visit new_session_path

    # Phone tab should have active styling
    phone_tab = page.find('[data-login-toggle-target="phoneTab"]')
    expect(phone_tab[:class]).to include('bg-white')

    # Email tab should have inactive styling
    email_tab = page.find('[data-login-toggle-target="emailTab"]')
    expect(email_tab[:class]).to include('text-gray-500')
    expect(email_tab[:class]).not_to include('bg-white')
  end

  scenario 'Phone form has SMS login button' do
    visit new_session_path

    # Check for SMS login button
    expect(page).to have_button('Request SMS login code')
  end
end
