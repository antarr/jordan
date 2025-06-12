require 'rails_helper'

RSpec.describe User, 'WebAuthn functionality', type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to have_many(:webauthn_credentials).dependent(:destroy) }
  end

  describe '#two_factor_enabled?' do
    context 'when two_factor_enabled is false' do
      before { user.update(two_factor_enabled: false) }

      it 'returns false' do
        expect(user.two_factor_enabled?).to be false
      end

      it 'returns false even with credentials' do
        create(:webauthn_credential, user: user)
        expect(user.two_factor_enabled?).to be false
      end
    end

    context 'when two_factor_enabled is true' do
      before { user.update(two_factor_enabled: true) }

      it 'returns false without credentials' do
        expect(user.two_factor_enabled?).to be false
      end

      it 'returns true with credentials' do
        create(:webauthn_credential, user: user)
        expect(user.two_factor_enabled?).to be true
      end
    end
  end

  describe '#enable_two_factor!' do
    it 'sets two_factor_enabled to true' do
      expect { user.enable_two_factor! }.to change { user.reload.two_factor_enabled }.to(true)
    end
  end

  describe '#disable_two_factor!' do
    before do
      user.update(two_factor_enabled: true)
      create_list(:webauthn_credential, 2, user: user)
    end

    it 'sets two_factor_enabled to false' do
      expect { user.disable_two_factor! }.to change { user.reload.two_factor_enabled }.to(false)
    end

    it 'destroys all webauthn credentials' do
      expect { user.disable_two_factor! }.to change { user.webauthn_credentials.count }.to(0)
    end
  end

  describe '#webauthn_user_id' do
    it 'returns the user id as a string' do
      expect(user.webauthn_user_id).to eq(user.id.to_s)
    end
  end
end
