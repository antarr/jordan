# frozen_string_literal: true

class SmsService
  class << self
    def send_verification_code(phone_number, code)
      # In development/test, log the code instead of sending SMS
      if Rails.env.development? || Rails.env.test?
        Rails.logger.info "SMS Verification Code for #{phone_number}: #{code}"
        return true
      end

      # In production, integrate with an SMS service like Twilio
      # For now, we'll simulate success
      Rails.logger.info "Would send SMS verification code #{code} to #{phone_number}"
      true
    rescue StandardError => e
      Rails.logger.error "Failed to send SMS to #{phone_number}: #{e.message}"
      false
    end

    def send_login_code(phone_number, code)
      # Similar to verification code but for login
      if Rails.env.development? || Rails.env.test?
        Rails.logger.info "SMS Login Code for #{phone_number}: #{code}"
        return true
      end

      Rails.logger.info "Would send SMS login code #{code} to #{phone_number}"
      true
    rescue StandardError => e
      Rails.logger.error "Failed to send login SMS to #{phone_number}: #{e.message}"
      false
    end

    # Example Twilio integration (commented out)
    # def send_sms_via_twilio(phone_number, message)
    #   client = Twilio::REST::Client.new(
    #     Rails.application.credentials.twilio[:account_sid],
    #     Rails.application.credentials.twilio[:auth_token]
    #   )
    #
    #   client.messages.create(
    #     from: Rails.application.credentials.twilio[:phone_number],
    #     to: phone_number,
    #     body: message
    #   )
    # end
  end
end
