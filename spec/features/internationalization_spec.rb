require 'rails_helper'

RSpec.describe 'Internationalization', type: :feature do
  describe 'Language switching' do
    it 'displays content in English by default' do
      visit '/en/session/new'
      expect(page).to have_content('Sign In')
      expect(page).to have_content('English')
    end

    it 'displays content in Spanish when locale is set to es' do
      visit '/es/session/new'
      expect(page).to have_content('Iniciar Sesión')
      expect(page).to have_content('Español')
    end

    it 'displays content in Brazilian Portuguese when locale is set to pt-BR' do
      visit '/pt-BR/session/new'
      expect(page).to have_content('Entrar')
      expect(page).to have_content('Português (BR)')
    end

    # Note: Root redirect test would require more complex setup
    # it 'redirects root path to default locale' do
    #   visit '/'
    #   expect(current_url).to include('/en')
    # end

    it 'shows language switcher with all available languages' do
      visit '/en/session/new'
      expect(page).to have_content('🇺🇸 English')
      expect(page).to have_link('🇪🇸 Español')
      expect(page).to have_link('🇧🇷 Português (BR)')
    end

    it 'allows switching languages via URL parameters' do
      visit '/en/session/new'
      expect(page).to have_content('Sign In')
      
      # Click on Spanish language link
      click_link '🇪🇸 Español'
      expect(current_path).to eq('/es/session/new')
      expect(page).to have_content('Iniciar Sesión')
      
      # Click on Portuguese language link
      click_link '🇧🇷 Português (BR)'
      expect(current_path).to eq('/pt-BR/session/new')
      expect(page).to have_content('Entrar')
    end
  end

  describe 'Flash messages localization' do
    let(:user) { create(:user, :email_user, email_verified_at: nil) }

    it 'displays flash messages in the selected language', js: true do
      visit '/es/session/new'
      
      # Switch to email mode since phone is the default
      click_button 'Correo Electrónico'
      
      # Wait for email fields to be visible
      expect(page).to have_field('email', visible: true)
      
      fill_in 'email', with: user.email
      fill_in 'password', with: user.password
      click_button 'Iniciar Sesión'
      
      expect(page).to have_content('Por favor verifica tu dirección de correo electrónico antes de iniciar sesión.')
    end
  end
end