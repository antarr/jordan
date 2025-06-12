require 'rails_helper'

RSpec.describe JwtService do
  describe '.encode' do
    let(:payload) { { user_id: 1 } }

    it 'returns a JWT token' do
      token = described_class.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').count).to eq(3)
    end

    it 'includes expiration time' do
      token = described_class.encode(payload)
      decoded = JWT.decode(token, JwtService::SECRET_KEY)[0]
      expect(decoded['exp']).to be_present
    end

    it 'accepts custom expiration time' do
      exp = 1.hour.from_now
      token = described_class.encode(payload, exp)
      decoded = JWT.decode(token, JwtService::SECRET_KEY)[0]
      expect(decoded['exp']).to eq(exp.to_i)
    end
  end

  describe '.decode' do
    let(:payload) { { user_id: 1 } }
    let(:token) { described_class.encode(payload) }

    it 'returns the original payload' do
      decoded = described_class.decode(token)
      expect(decoded[:user_id]).to eq(1)
    end

    it 'returns a HashWithIndifferentAccess' do
      decoded = described_class.decode(token)
      expect(decoded).to be_a(HashWithIndifferentAccess)
      expect(decoded['user_id']).to eq(1)
      expect(decoded[:user_id]).to eq(1)
    end

    it 'raises JWT::DecodeError for invalid token' do
      expect do
        described_class.decode('invalid.token.here')
      end.to raise_error(JWT::DecodeError)
    end

    it 'raises JWT::ExpiredSignature for expired token' do
      expired_token = described_class.encode(payload, 1.second.ago)
      expect do
        described_class.decode(expired_token)
      end.to raise_error(JWT::ExpiredSignature)
    end
  end

  describe 'refresh token functionality' do
    before do
      allow(Rails.application.config).to receive(:jwt).and_return({
                                                                    refresh_tokens_enabled: true,
                                                                    access_token_expiry: 15.minutes,
                                                                    refresh_token_expiry: 30.days,
                                                                    access_token_type: 'access',
                                                                    refresh_token_type: 'refresh'
                                                                  })
    end

    describe '.encode_access_token' do
      it 'returns an access token with correct type' do
        token = described_class.encode_access_token(1)
        decoded = described_class.decode(token)
        expect(decoded[:type]).to eq('access')
        expect(decoded[:user_id]).to eq(1)
      end

      it 'uses configured expiry time when refresh tokens enabled' do
        token = described_class.encode_access_token(1)
        decoded = described_class.decode(token)
        expect(decoded[:exp]).to be_within(2).of(15.minutes.from_now.to_i)
      end
    end

    describe '.encode_refresh_token' do
      it 'returns a refresh token with correct type' do
        token = described_class.encode_refresh_token(1)
        decoded = described_class.decode(token)
        expect(decoded[:type]).to eq('refresh')
        expect(decoded[:user_id]).to eq(1)
      end

      it 'uses configured expiry time' do
        token = described_class.encode_refresh_token(1)
        decoded = described_class.decode(token)
        expect(decoded[:exp]).to be_within(2).of(30.days.from_now.to_i)
      end

      context 'when refresh tokens disabled' do
        before do
          allow(Rails.application.config).to receive(:jwt).and_return({
                                                                        refresh_tokens_enabled: false
                                                                      })
        end

        it 'raises error' do
          expect do
            described_class.encode_refresh_token(1)
          end.to raise_error('Refresh tokens are not enabled')
        end
      end
    end

    describe '.decode_refresh_token' do
      it 'decodes valid refresh token' do
        token = described_class.encode_refresh_token(1)
        decoded = described_class.decode_refresh_token(token)
        expect(decoded[:user_id]).to eq(1)
        expect(decoded[:type]).to eq('refresh')
      end

      it 'raises error for access token' do
        token = described_class.encode_access_token(1)
        expect do
          described_class.decode_refresh_token(token)
        end.to raise_error(JWT::DecodeError, 'Invalid token type')
      end
    end
  end
end
