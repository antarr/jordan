require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#language_switcher' do
    before do
      allow(helper).to receive(:url_for).and_return('/test-url')
    end

    it 'returns a div with language-switcher class' do
      result = helper.language_switcher
      expect(result).to match(/<div[^>]*class="language-switcher"/)
    end

    it 'displays current language as span when it matches I18n.locale' do
      I18n.locale = :en
      result = helper.language_switcher
      expect(result).to include('<span class="current-language">🇺🇸 English</span>')
    end

    it 'displays other languages as links when they do not match I18n.locale' do
      I18n.locale = :en
      result = helper.language_switcher
      expect(result).to include('href="/test-url"')
      expect(result).to include('class="language-link"')
      expect(result).to include('🇪🇸 Español')
      expect(result).to include('🇧🇷 Português (BR)')
    end

    it 'includes all available locales' do
      result = helper.language_switcher
      expect(result).to include('English')
      expect(result).to include('Español')
      expect(result).to include('Português (BR)')
    end

    it 'separates languages with pipe character' do
      result = helper.language_switcher
      expect(result).to include(' | ')
    end

    it 'marks result as html_safe' do
      result = helper.language_switcher
      expect(result).to be_html_safe
    end

    context 'when locale is Spanish' do
      before { I18n.locale = :es }
      after { I18n.locale = :en }

      it 'shows Spanish as current language' do
        result = helper.language_switcher
        expect(result).to include('<span class="current-language">🇪🇸 Español</span>')
        expect(result).not_to include('<span class="current-language">🇺🇸 English</span>')
      end
    end

    context 'when locale is Brazilian Portuguese' do
      before { I18n.locale = :'pt-BR' }
      after { I18n.locale = :en }

      it 'shows Portuguese as current language' do
        result = helper.language_switcher
        expect(result).to include('<span class="current-language">🇧🇷 Português (BR)</span>')
        expect(result).not_to include('<span class="current-language">🇺🇸 English</span>')
      end
    end
  end

  describe '#current_language_name' do
    context 'when locale is English' do
      before { I18n.locale = :en }
      after { I18n.locale = :en }

      it 'returns English' do
        expect(helper.current_language_name).to eq('English')
      end
    end

    context 'when locale is Spanish' do
      before { I18n.locale = :es }
      after { I18n.locale = :en }

      it 'returns Español' do
        expect(helper.current_language_name).to eq('Español')
      end
    end

    context 'when locale is Brazilian Portuguese' do
      before { I18n.locale = :'pt-BR' }
      after { I18n.locale = :en }

      it 'returns Português (BR)' do
        expect(helper.current_language_name).to eq('Português (BR)')
      end
    end

    context 'when locale is unsupported' do
      before do
        I18n.config.available_locales += [:fr]
        I18n.locale = :fr
      end
      
      after do
        I18n.locale = :en
        I18n.config.available_locales -= [:fr]
      end

      it 'returns humanized version of locale' do
        expect(helper.current_language_name).to eq('fr'.humanize)
      end
    end
  end

  describe '#feature_enabled?' do
    context 'when feature is enabled' do
      before do
        allow(Rails.application.config).to receive(:features).and_return({ phone_registration_enabled: true })
      end

      it 'returns true for enabled feature' do
        expect(helper.feature_enabled?(:phone_registration_enabled)).to be true
      end
    end

    context 'when feature is disabled' do
      before do
        allow(Rails.application.config).to receive(:features).and_return({ phone_registration_enabled: false })
      end

      it 'returns false for disabled feature' do
        expect(helper.feature_enabled?(:phone_registration_enabled)).to be false
      end
    end

    context 'when feature is not configured' do
      before do
        allow(Rails.application.config).to receive(:features).and_return({})
      end

      it 'returns false for unconfigured feature' do
        expect(helper.feature_enabled?(:unknown_feature)).to be false
      end
    end
  end
end