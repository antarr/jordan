require 'rails_helper'

RSpec.describe WebauthnCredential, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:webauthn_credential) }

    it { is_expected.to validate_presence_of(:webauthn_id) }
    it { is_expected.to validate_uniqueness_of(:webauthn_id) }
    it { is_expected.to validate_presence_of(:public_key) }
    it { is_expected.to validate_presence_of(:nickname) }
    it { is_expected.to validate_uniqueness_of(:nickname).scoped_to(:user_id) }
    it { is_expected.to validate_numericality_of(:sign_count).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:credential1) { create(:webauthn_credential, user: user) }
    let!(:credential2) { create(:webauthn_credential) }

    describe '.for_user' do
      it 'returns credentials for the specified user' do
        expect(WebauthnCredential.for_user(user)).to contain_exactly(credential1)
      end
    end
  end

  describe '#increment_sign_count!' do
    let(:credential) { create(:webauthn_credential, sign_count: 5) }

    it 'increments the sign count' do
      expect { credential.increment_sign_count! }.to change { credential.reload.sign_count }.by(1)
    end
  end

  describe 'before_validation callback' do
    it 'sets default sign_count to 0' do
      credential = WebauthnCredential.new(
        user: user,
        webauthn_id: 'test-id',
        public_key: 'test-key',
        nickname: 'Test Key'
      )
      credential.valid?
      expect(credential.sign_count).to eq(0)
    end

    it 'does not override existing sign_count' do
      credential = WebauthnCredential.new(
        user: user,
        webauthn_id: 'test-id',
        public_key: 'test-key',
        nickname: 'Test Key',
        sign_count: 10
      )
      credential.valid?
      expect(credential.sign_count).to eq(10)
    end
  end
end
