require 'rails_helper'

RSpec.describe SmsService, type: :service do
  let(:phone_user) { create(:user, :phone_user, :step_two) }

  describe '.send_verification_code' do
    context 'in test environment' do
      it 'logs the SMS instead of sending' do
        expect(Rails.logger).to receive(:info).with("SMS Verification Code for #{phone_user.phone}: 123456")
        
        result = SmsService.send_verification_code(phone_user.phone, '123456')
        
        expect(result).to be true
      end

      it 'handles errors gracefully' do
        allow(Rails.logger).to receive(:info).and_raise(StandardError.new('Test error'))
        expect(Rails.logger).to receive(:error).with("Failed to send SMS to #{phone_user.phone}: Test error")
        
        result = SmsService.send_verification_code(phone_user.phone, '123456')
        
        expect(result).to be false
      end
    end
    
    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(Rails.env).to receive(:test?).and_return(false)
      end
      
      it 'logs production SMS sending behavior' do
        expect(Rails.logger).to receive(:info).with("Would send SMS verification code 123456 to #{phone_user.phone}")
        
        result = SmsService.send_verification_code(phone_user.phone, '123456')
        
        expect(result).to be true
      end
      
      it 'handles production errors gracefully' do
        allow(Rails.logger).to receive(:info).and_raise(StandardError.new('Production error'))
        expect(Rails.logger).to receive(:error).with("Failed to send SMS to #{phone_user.phone}: Production error")
        
        result = SmsService.send_verification_code(phone_user.phone, '123456')
        
        expect(result).to be false
      end
    end
  end

  describe '.send_login_code' do
    context 'in test environment' do
      it 'logs the SMS instead of sending' do
        expect(Rails.logger).to receive(:info).with("SMS Login Code for #{phone_user.phone}: 123456")
        
        result = SmsService.send_login_code(phone_user.phone, '123456')
        
        expect(result).to be true
      end

      it 'handles errors gracefully' do
        allow(Rails.logger).to receive(:info).and_raise(StandardError.new('Test error'))
        expect(Rails.logger).to receive(:error).with("Failed to send login SMS to #{phone_user.phone}: Test error")
        
        result = SmsService.send_login_code(phone_user.phone, '123456')
        
        expect(result).to be false
      end
    end
    
    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(Rails.env).to receive(:test?).and_return(false)
      end
      
      it 'logs production SMS sending behavior' do
        expect(Rails.logger).to receive(:info).with("Would send SMS login code 123456 to #{phone_user.phone}")
        
        result = SmsService.send_login_code(phone_user.phone, '123456')
        
        expect(result).to be true
      end
      
      it 'handles production errors gracefully' do
        allow(Rails.logger).to receive(:info).and_raise(StandardError.new('Production error'))
        expect(Rails.logger).to receive(:error).with("Failed to send login SMS to #{phone_user.phone}: Production error")
        
        result = SmsService.send_login_code(phone_user.phone, '123456')
        
        expect(result).to be false
      end
    end
  end
end