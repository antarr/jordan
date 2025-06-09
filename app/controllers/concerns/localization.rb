# frozen_string_literal: true

module Localization
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    I18n.locale = locale_from_params || locale_from_session || locale_from_accept_language || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def locale_from_params
    locale = params[:locale]
    locale if I18n.available_locales.map(&:to_s).include?(locale)
  end

  def locale_from_session
    locale = session[:locale]
    locale if I18n.available_locales.map(&:to_s).include?(locale)
  end

  def locale_from_accept_language
    locale = extract_locale_from_accept_language_header
    locale if I18n.available_locales.map(&:to_s).include?(locale)
  end

  def extract_locale_from_accept_language_header
    return unless request.env['HTTP_ACCEPT_LANGUAGE']

    parsed_locales = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/([a-z]{2}(-[A-Z]{2})?)\b/)
    parsed_locales.map(&:first).find { |locale| I18n.available_locales.map(&:to_s).include?(locale) }
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
