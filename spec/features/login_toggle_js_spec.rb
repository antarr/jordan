require 'rails_helper'

RSpec.feature 'Login Toggle JavaScript', :js, type: :feature do
  scenario 'User can toggle between forms using JavaScript', :js do
    visit new_session_path

    # Wait for page to load and Stimulus to connect
    expect(page).to have_content('Sign In')

    # Initially phone form should be visible (default)
    expect(page).to have_field('phone', visible: true)
    expect(page).not_to have_field('email', visible: true)

    # Click email tab
    click_button 'Email'

    # Now email form should be visible
    expect(page).to have_field('email', visible: true)
    expect(page).not_to have_field('phone', visible: true)

    # Click phone tab again
    click_button 'Phone'

    # Phone form should be visible again
    expect(page).to have_field('phone', visible: true)
    expect(page).not_to have_field('email', visible: true)
  end

  scenario 'Switching forms focuses the first field', :js do
    visit new_session_path

    # Phone field should be focused initially
    expect(page).to have_field('phone', focused: true)

    # Switch to email
    click_button 'Email'

    # Email field should now be focused
    expect(page).to have_field('email', focused: true)

    # Switch back to phone
    click_button 'Phone'

    # Phone field should be focused again
    expect(page).to have_field('phone', focused: true)
  end
end
