require 'rails_helper'

RSpec.feature 'Registration Form', :js, type: :feature do
  scenario 'Submit button is disabled initially', :js do
    visit new_registration_path

    # Wait for page to load and Stimulus to connect
    expect(page).to have_content('Sign Up')

    # Submit button should be disabled initially
    submit_button = find('input[type="submit"]')
    expect(submit_button).to be_disabled
    expect(submit_button[:class]).to include('opacity-50')
    expect(submit_button[:class]).to include('cursor-not-allowed')
  end

  scenario 'Submit button becomes enabled when option is selected', :js do
    visit new_registration_path

    # Wait for page to load
    expect(page).to have_content('Sign Up')

    # Submit button should be disabled initially
    submit_button = find('input[type="submit"]')
    expect(submit_button).to be_disabled

    # Select email option
    choose 'contact_method_email'

    # Submit button should now be enabled
    expect(submit_button).not_to be_disabled
    expect(submit_button[:class]).not_to include('opacity-50')
    expect(submit_button[:class]).not_to include('cursor-not-allowed')
  end

  scenario 'Submit button works with phone option if feature is enabled', :js do
    # Skip this test if phone registration is not enabled
    skip 'Phone registration is not enabled' unless Rails.application.config.features[:phone_registration_enabled]

    visit new_registration_path

    # Wait for page to load
    expect(page).to have_content('Sign Up')

    # Submit button should be disabled initially
    submit_button = find('input[type="submit"]')
    expect(submit_button).to be_disabled

    # Select phone option
    choose 'contact_method_phone'

    # Submit button should now be enabled
    expect(submit_button).not_to be_disabled
    expect(submit_button[:class]).not_to include('opacity-50')
  end
end
