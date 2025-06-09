require 'rails_helper'

RSpec.describe Localization, type: :controller do
  controller(ApplicationController) do
    def index
      render plain: 'test'
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe '#set_locale' do
    it 'sets locale from params when valid' do
      get :index, params: { locale: 'es' }
      expect(I18n.locale).to eq(:es)
      expect(session[:locale]).to eq(:es)
    end

    it 'ignores invalid locale from params' do
      get :index, params: { locale: 'invalid' }
      expect(I18n.locale).to eq(:en)
      expect(session[:locale]).to eq(:en)
    end

    it 'sets locale from session when params absent' do
      session[:locale] = 'es'
      get :index
      expect(I18n.locale).to eq(:es)
    end

    it 'ignores invalid locale from session' do
      session[:locale] = 'invalid'
      get :index
      expect(I18n.locale).to eq(:en)
    end

    it 'sets locale from accept language header' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'es-ES,es;q=0.9,en;q=0.8'
      get :index
      expect(I18n.locale).to eq(:es)
    end

    it 'falls back to default locale when no valid options' do
      get :index
      expect(I18n.locale).to eq(:en)
    end

    it 'prioritizes params over session and accept language' do
      session[:locale] = 'es'
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'pt-BR,pt;q=0.9'
      get :index, params: { locale: 'en' }
      expect(I18n.locale).to eq(:en)
    end

    it 'prioritizes session over accept language' do
      session[:locale] = 'es'
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'pt-BR,pt;q=0.9'
      get :index
      expect(I18n.locale).to eq(:es)
    end
  end

  describe '#locale_from_params' do
    it 'returns valid locale from params' do
      controller.params = { locale: 'es' }
      expect(controller.send(:locale_from_params)).to eq('es')
    end

    it 'returns nil for invalid locale' do
      controller.params = { locale: 'invalid' }
      expect(controller.send(:locale_from_params)).to be_nil
    end

    it 'returns nil when locale param is missing' do
      controller.params = {}
      expect(controller.send(:locale_from_params)).to be_nil
    end
  end

  describe '#locale_from_session' do
    it 'returns valid locale from session' do
      session[:locale] = 'es'
      expect(controller.send(:locale_from_session)).to eq('es')
    end

    it 'returns nil for invalid locale' do
      session[:locale] = 'invalid'
      expect(controller.send(:locale_from_session)).to be_nil
    end

    it 'returns nil when session locale is missing' do
      expect(controller.send(:locale_from_session)).to be_nil
    end
  end

  describe '#locale_from_accept_language' do
    it 'returns valid locale from accept language header' do
      allow(controller).to receive(:extract_locale_from_accept_language_header).and_return('es')
      expect(controller.send(:locale_from_accept_language)).to eq('es')
    end

    it 'returns nil for invalid locale from header' do
      allow(controller).to receive(:extract_locale_from_accept_language_header).and_return('invalid')
      expect(controller.send(:locale_from_accept_language)).to be_nil
    end

    it 'returns nil when header extraction returns nil' do
      allow(controller).to receive(:extract_locale_from_accept_language_header).and_return(nil)
      expect(controller.send(:locale_from_accept_language)).to be_nil
    end
  end

  describe '#extract_locale_from_accept_language_header' do
    it 'returns nil when HTTP_ACCEPT_LANGUAGE header is missing' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = nil
      expect(controller.send(:extract_locale_from_accept_language_header)).to be_nil
    end

    it 'extracts simple locale from header' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'es'
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('es')
    end

    it 'extracts locale with country code' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'pt-BR'
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('pt-BR')
    end

    it 'extracts first supported locale from multiple options' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr,es;q=0.9,en;q=0.8'
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('es')
    end

    it 'extracts locale with quality values' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'es-ES,es;q=0.9,en;q=0.8'
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('es')
    end

    it 'returns nil when no supported locales found' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr,de;q=0.8,it;q=0.6'
      expect(controller.send(:extract_locale_from_accept_language_header)).to be_nil
    end

    it 'handles malformed headers gracefully' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'invalid-header-format'
      expect(controller.send(:extract_locale_from_accept_language_header)).to be_nil
    end

    it 'extracts from complex header with multiple languages' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'en-US,en;q=0.9,es-ES;q=0.8,es;q=0.7,pt-BR;q=0.6,pt;q=0.5'
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('en')
    end

    it 'prioritizes pt-BR over en when pt-BR appears first' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'pt-BR,pt;q=0.9,en;q=0.8'
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('pt-BR')
    end

    it 'handles case variations correctly' do
      # The regex is strict about case: lowercase language, uppercase country
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'ES,pt-br,en;q=0.8'
      # 'ES' won't match (needs lowercase), 'pt-br' won't match (needs uppercase country), 'en' will match
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('en')
    end

    it 'extracts locale with underscore separator (though uncommon)' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'pt_BR,en;q=0.8'
      # This tests that underscores are not matched by the current regex
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('en')
    end

    it 'handles empty string header' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = ''
      expect(controller.send(:extract_locale_from_accept_language_header)).to be_nil
    end

    it 'handles whitespace in header' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = ' es , en;q=0.8 '
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('es')
    end

    context 'with all supported locales' do
      it 'finds English' do
        request.env['HTTP_ACCEPT_LANGUAGE'] = 'en-US,en;q=0.9'
        expect(controller.send(:extract_locale_from_accept_language_header)).to eq('en')
      end

      it 'finds Spanish' do
        request.env['HTTP_ACCEPT_LANGUAGE'] = 'es-ES,es;q=0.9'
        expect(controller.send(:extract_locale_from_accept_language_header)).to eq('es')
      end

      it 'finds Portuguese Brazilian' do
        request.env['HTTP_ACCEPT_LANGUAGE'] = 'pt-BR,pt;q=0.9'
        expect(controller.send(:extract_locale_from_accept_language_header)).to eq('pt-BR')
      end
    end
  end

  describe '#default_url_options' do
    it 'includes current locale in URL options' do
      I18n.locale = :es
      expect(controller.send(:default_url_options)).to eq({ locale: :es })
    end

    it 'updates when locale changes' do
      I18n.locale = :en
      expect(controller.send(:default_url_options)).to eq({ locale: :en })
      
      I18n.locale = :'pt-BR'
      expect(controller.send(:default_url_options)).to eq({ locale: :'pt-BR' })
    end
  end
end