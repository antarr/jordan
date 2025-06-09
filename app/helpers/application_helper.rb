module ApplicationHelper
  def language_switcher
    available_locales = {
      en: { name: 'English', flag: '🇺🇸' },
      es: { name: 'Español', flag: '🇪🇸' },
      'pt-BR': { name: 'Português (BR)', flag: '🇧🇷' }
    }

    content_tag :div, class: 'language-switcher' do
      available_locales.map do |locale, info|
        if locale.to_s == I18n.locale.to_s
          content_tag :span, "#{info[:flag]} #{info[:name]}", class: 'current-language'
        else
          link_to "#{info[:flag]} #{info[:name]}",
                  url_for(locale: locale),
                  class: 'language-link'
        end
      end.join(' | ').html_safe
    end
  end

  def current_language_name
    case I18n.locale.to_s
    when 'en'
      'English'
    when 'es'
      'Español'
    when 'pt-BR'
      'Português (BR)'
    else
      I18n.locale.to_s.humanize
    end
  end

  def feature_enabled?(feature_name)
    Rails.application.config.features[feature_name] || false
  end
end
