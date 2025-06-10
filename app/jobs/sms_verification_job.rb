# frozen_string_literal: true

class SmsVerificationJob < ApplicationJob
  queue_as :default

  def perform(user)
    return unless user.phone.present? && user.sms_verification_code.present?

    success = SmsService.send_verification_code(user.phone, user.sms_verification_code)

    return if success

    Rails.logger.error "Failed to send SMS verification to user #{user.id} (#{user.phone})"
  end
end
