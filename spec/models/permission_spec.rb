require 'rails_helper'

RSpec.describe Permission, type: :model do
  subject { build(:permission) }
  let(:permission) { create(:permission) }

  describe 'associations' do
    it { should have_many(:role_permissions).dependent(:destroy) }
    it { should have_many(:roles).through(:role_permissions) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:resource) }
    it { should validate_presence_of(:action) }
    it { should validate_presence_of(:description) }

    describe 'unique_resource_action_combination' do
      it 'validates resource and action combination is unique' do
        create(:permission, resource: 'users', action: 'read')
        duplicate = build(:permission, resource: 'users', action: 'read')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:base]).to include('Resource and action combination must be unique')
      end

      it 'allows same resource with different action' do
        create(:permission, resource: 'users', action: 'read')
        different_action = build(:permission, resource: 'users', action: 'create')

        expect(different_action).to be_valid
      end

      it 'allows same action with different resource' do
        create(:permission, resource: 'users', action: 'read')
        different_resource = build(:permission, resource: 'posts', action: 'read')

        expect(different_resource).to be_valid
      end

      it 'allows updating existing permission without validation error' do
        permission = create(:permission, resource: 'users', action: 'read')
        permission.description = 'Updated description'

        expect(permission).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:user_read) { create(:permission, resource: 'users', action: 'read') }
    let!(:user_create) { create(:permission, resource: 'users', action: 'create') }
    let!(:post_read) { create(:permission, resource: 'posts', action: 'read') }

    describe '.for_resource' do
      it 'returns permissions for specific resource' do
        expect(Permission.for_resource('users')).to include(user_read, user_create)
        expect(Permission.for_resource('users')).not_to include(post_read)
      end
    end

    describe '.for_action' do
      it 'returns permissions for specific action' do
        expect(Permission.for_action('read')).to include(user_read, post_read)
        expect(Permission.for_action('read')).not_to include(user_create)
      end
    end
  end

  describe '#full_name' do
    it 'returns resource.action format' do
      permission = build(:permission, resource: 'users', action: 'read')
      expect(permission.full_name).to eq('users.read')
    end
  end

  describe '.find_by_resource_action' do
    it 'finds permission by resource and action' do
      permission = create(:permission, resource: 'users', action: 'read')
      found = Permission.find_by_resource_action('users', 'read')

      expect(found).to eq(permission)
    end

    it 'returns nil when permission not found' do
      found = Permission.find_by_resource_action('nonexistent', 'read')
      expect(found).to be_nil
    end
  end

  describe 'factory traits' do
    it 'creates read permission' do
      permission = create(:permission, :read_permission)
      expect(permission.action).to eq('read')
    end

    it 'creates write permission' do
      permission = create(:permission, :write_permission)
      expect(permission.action).to eq('create')
    end

    it 'creates dashboard access permission' do
      permission = create(:permission, :dashboard_access)
      expect(permission.name).to eq('dashboard.read')
      expect(permission.resource).to eq('dashboard')
      expect(permission.action).to eq('read')
    end

    it 'creates user read permission' do
      permission = create(:permission, :user_read)
      expect(permission.name).to eq('users.read')
      expect(permission.resource).to eq('users')
      expect(permission.action).to eq('read')
    end
  end
end
