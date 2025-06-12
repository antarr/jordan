require 'rails_helper'

RSpec.feature 'Login Form Toggle', :js, type: :feature do
  scenario 'User can toggle between email and phone login forms' do
    visit new_session_path

    # Phone form should be visible by default
    expect(page).to have_selector('[data-login-toggle-target="phoneForm"]:not(.hidden)')
    expect(page).to have_selector('[data-login-toggle-target="emailForm"].hidden', visible: :all)

    # Phone tab should be active
    expect(page).to have_selector('[data-login-toggle-target="phoneTab"].bg-white')
    expect(page).to have_selector('[data-login-toggle-target="emailTab"]:not(.bg-white)')

    # Click email tab
    find('[data-login-toggle-target="emailTab"]').click

    # Email form should now be visible
    expect(page).to have_selector('[data-login-toggle-target="emailForm"]:not(.hidden)')
    expect(page).to have_selector('[data-login-toggle-target="phoneForm"].hidden', visible: :all)

    # Email tab should be active
    expect(page).to have_selector('[data-login-toggle-target="emailTab"].bg-white')
    expect(page).to have_selector('[data-login-toggle-target="phoneTab"]:not(.bg-white)')

    # Click phone tab again
    find('[data-login-toggle-target="phoneTab"]').click

    # Phone form should be visible again
    expect(page).to have_selector('[data-login-toggle-target="phoneForm"]:not(.hidden)')
    expect(page).to have_selector('[data-login-toggle-target="emailForm"].hidden', visible: :all)
  end

  scenario 'Phone form is default and contains expected fields' do
    visit new_session_path

    # Check phone form fields are present
    within('[data-login-toggle-target="phoneForm"]') do
      expect(page).to have_field('phone')
      expect(page).to have_field('sms_code')
      expect(page).to have_field('password')
      expect(page).to have_button('Sign In')
      expect(page).to have_button('Request SMS login code')
    end
  end

  scenario 'Email form contains expected fields when selected' do
    visit new_session_path

    # Switch to email form
    find('[data-login-toggle-target="emailTab"]').click

    # Check email form fields are present
    within('[data-login-toggle-target="emailForm"]') do
      expect(page).to have_field('email')
      expect(page).to have_field('password')
      expect(page).to have_button('Sign In')
    end
  end
end
