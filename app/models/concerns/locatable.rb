# frozen_string_literal: true

module Locatable
  extend ActiveSupport::Concern

  included do
    validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, if: lambda {
      latitude.present?
    }
    validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, if: lambda {
      longitude.present?
    }
    validates :latitude, presence: true, if: -> { longitude.present? }
    validates :longitude, presence: true, if: -> { latitude.present? }
  end

  def has_location?
    latitude.present? && longitude.present?
  end

  def location_coordinates
    return nil unless has_location?

    [latitude.to_f, longitude.to_f]
  end

  def location_display
    return 'Location not set' unless has_location?

    if location_name.present?
      location_name
    else
      "#{latitude.round(4)}, #{longitude.round(4)}"
    end
  end

  def location_public?
    has_location? && !location_private?
  end
end