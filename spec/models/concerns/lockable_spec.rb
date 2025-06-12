require 'rails_helper'

RSpec.describe Lockable, type: :concern do
  # Create a dummy class to test the concern
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Lockable

      attribute :locked_at, :datetime
      attribute :locked_by_admin, :boolean, default: false
      attribute :failed_login_attempts, :integer, default: 0
      attribute :last_failed_login_at, :datetime
      attribute :auto_unlock_token, :string

      def update!(attributes)
        attributes.each { |key, value| send("#{key}=", value) }
        save!
      end

      def save!
        true
      end
    end
  end

  let(:lockable_object) { dummy_class.new }

  describe 'constants' do
    it 'defines MAX_FAILED_LOGIN_ATTEMPTS' do
      expect(Lockable::MAX_FAILED_LOGIN_ATTEMPTS).to eq(5)
    end

    it 'defines FAILED_LOGIN_RESET_TIME' do
      expect(Lockable::FAILED_LOGIN_RESET_TIME).to eq(24.hours)
    end
  end

  describe '#locked?' do
    it 'returns true when locked_at is present' do
      lockable_object.locked_at = Time.current
      expect(lockable_object.locked?).to be true
    end

    it 'returns false when locked_at is nil' do
      lockable_object.locked_at = nil
      expect(lockable_object.locked?).to be false
    end
  end

  describe '#unlocked?' do
    it 'returns false when locked_at is present' do
      lockable_object.locked_at = Time.current
      expect(lockable_object.unlocked?).to be false
    end

    it 'returns true when locked_at is nil' do
      lockable_object.locked_at = nil
      expect(lockable_object.unlocked?).to be true
    end
  end

  describe '#auto_locked?' do
    it 'returns true when locked and not locked by admin' do
      lockable_object.locked_at = Time.current
      lockable_object.locked_by_admin = false
      expect(lockable_object.auto_locked?).to be true
    end

    it 'returns false when locked by admin' do
      lockable_object.locked_at = Time.current
      lockable_object.locked_by_admin = true
      expect(lockable_object.auto_locked?).to be false
    end

    it 'returns false when not locked' do
      lockable_object.locked_at = nil
      lockable_object.locked_by_admin = false
      expect(lockable_object.auto_locked?).to be false
    end
  end

  describe '#admin_locked?' do
    it 'returns true when locked by admin' do
      lockable_object.locked_at = Time.current
      lockable_object.locked_by_admin = true
      expect(lockable_object.admin_locked?).to be true
    end

    it 'returns false when auto-locked' do
      lockable_object.locked_at = Time.current
      lockable_object.locked_by_admin = false
      expect(lockable_object.admin_locked?).to be false
    end

    it 'returns false when not locked' do
      lockable_object.locked_at = nil
      lockable_object.locked_by_admin = true
      expect(lockable_object.admin_locked?).to be false
    end
  end

  describe '#can_self_unlock?' do
    it 'returns true when auto-locked' do
      lockable_object.locked_at = Time.current
      lockable_object.locked_by_admin = false
      expect(lockable_object.can_self_unlock?).to be true
    end

    it 'returns false when admin-locked' do
      lockable_object.locked_at = Time.current
      lockable_object.locked_by_admin = true
      expect(lockable_object.can_self_unlock?).to be false
    end

    it 'returns false when not locked' do
      lockable_object.locked_at = nil
      expect(lockable_object.can_self_unlock?).to be false
    end
  end

  describe '#active_for_authentication?' do
    it 'returns false when locked' do
      lockable_object.locked_at = Time.current
      expect(lockable_object.active_for_authentication?).to be false
    end

    it 'returns true when not locked' do
      lockable_object.locked_at = nil
      expect(lockable_object.active_for_authentication?).to be true
    end
  end

  describe '#lock_account!' do
    it 'sets locked_at timestamp with admin_locked false by default' do
      travel_to Time.current do
        lockable_object.lock_account!
        expect(lockable_object.locked_at).to eq(Time.current)
        expect(lockable_object.locked_by_admin).to be false
      end
    end

    it 'sets locked_by_admin to true when admin_locked parameter is true' do
      travel_to Time.current do
        lockable_object.lock_account!(admin_locked: true)
        expect(lockable_object.locked_at).to eq(Time.current)
        expect(lockable_object.locked_by_admin).to be true
      end
    end
  end

  describe '#unlock_account!' do
    before do
      lockable_object.locked_at = Time.current
      lockable_object.locked_by_admin = true
      lockable_object.failed_login_attempts = 3
      lockable_object.auto_unlock_token = 'token123'
    end

    it 'clears all locking-related fields' do
      lockable_object.unlock_account!

      expect(lockable_object.locked_at).to be_nil
      expect(lockable_object.locked_by_admin).to be false
      expect(lockable_object.failed_login_attempts).to eq(0)
      expect(lockable_object.auto_unlock_token).to be_nil
    end
  end

  describe '#record_failed_login!' do
    it 'increments failed login attempts' do
      expect do
        lockable_object.record_failed_login!
      end.to change(lockable_object, :failed_login_attempts).from(0).to(1)
    end

    it 'sets last_failed_login_at to current time' do
      travel_to Time.current do
        lockable_object.record_failed_login!
        expect(lockable_object.last_failed_login_at).to eq(Time.current)
      end
    end

    it 'auto-locks account when max attempts reached' do
      lockable_object.failed_login_attempts = 4

      travel_to Time.current do
        lockable_object.record_failed_login!

        expect(lockable_object.locked_at).to eq(Time.current)
        expect(lockable_object.locked_by_admin).to be false
        expect(lockable_object.auto_unlock_token).to be_present
      end
    end

    it 'resets failed attempts if last failed login was more than 24 hours ago' do
      lockable_object.failed_login_attempts = 3
      lockable_object.last_failed_login_at = 25.hours.ago

      lockable_object.record_failed_login!

      expect(lockable_object.failed_login_attempts).to eq(1)
    end

    it 'does not reset failed attempts if last failed login was less than 24 hours ago' do
      lockable_object.failed_login_attempts = 3
      lockable_object.last_failed_login_at = 23.hours.ago

      lockable_object.record_failed_login!

      expect(lockable_object.failed_login_attempts).to eq(4)
    end
  end

  describe '#reset_failed_login_attempts!' do
    before do
      lockable_object.failed_login_attempts = 3
      lockable_object.last_failed_login_at = Time.current
    end

    it 'resets failed login attempts and last failed login time' do
      lockable_object.reset_failed_login_attempts!

      expect(lockable_object.failed_login_attempts).to eq(0)
      expect(lockable_object.last_failed_login_at).to be_nil
    end
  end

  describe '#generate_auto_unlock_token' do
    it 'generates a secure token' do
      lockable_object.generate_auto_unlock_token
      expect(lockable_object.auto_unlock_token).to be_present
      expect(lockable_object.auto_unlock_token.length).to be > 20
    end

    it 'generates different tokens each time' do
      lockable_object.generate_auto_unlock_token
      token1 = lockable_object.auto_unlock_token

      lockable_object.generate_auto_unlock_token
      token2 = lockable_object.auto_unlock_token

      expect(token1).not_to eq(token2)
    end
  end

  describe '#generate_auto_unlock_token!' do
    it 'generates token and saves' do
      expect(lockable_object).to receive(:save!)
      lockable_object.generate_auto_unlock_token!
      expect(lockable_object.auto_unlock_token).to be_present
    end
  end
end
