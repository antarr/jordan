require 'rails_helper'

RSpec.describe Role, type: :model do
  subject { build(:role) }
  let(:role) { create(:role) }
  let(:permission) { create(:permission) }

  describe 'associations' do
    it { should have_many(:role_permissions).dependent(:destroy) }
    it { should have_many(:permissions).through(:role_permissions) }
    it { should have_many(:users).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:description) }
  end

  describe 'scopes' do
    let!(:system_role) { create(:role, :system_role) }
    let!(:custom_role) { create(:role, :custom_role) }

    it 'filters system roles' do
      expect(Role.system_roles).to include(system_role)
      expect(Role.system_roles).not_to include(custom_role)
    end

    it 'filters custom roles' do
      expect(Role.custom_roles).to include(custom_role)
      expect(Role.custom_roles).not_to include(system_role)
    end
  end

  describe '#can?' do
    it 'returns true when role has the permission' do
      role.permissions << permission
      expect(role.can?(permission.name)).to be true
    end

    it 'returns false when role does not have the permission' do
      expect(role.can?(permission.name)).to be false
    end
  end

  describe '#can_access?' do
    it 'returns true when role has access to resource and action' do
      role.permissions << permission
      expect(role.can_access?(permission.resource, permission.action)).to be true
    end

    it 'returns false when role does not have access' do
      expect(role.can_access?(permission.resource, permission.action)).to be false
    end
  end

  describe 'role type checks' do
    it 'identifies admin role' do
      admin_role = create(:role, name: 'admin')
      expect(admin_role.admin?).to be true
      expect(role.admin?).to be false
    end

    it 'identifies moderator role' do
      moderator_role = create(:role, name: 'moderator')
      expect(moderator_role.moderator?).to be true
      expect(role.moderator?).to be false
    end

    it 'identifies user role' do
      user_role = create(:role, name: 'user')
      expect(user_role.user?).to be true
      expect(role.user?).to be false
    end

    it 'identifies system role' do
      system_role = create(:role, :system_role)
      expect(system_role.system?).to be true
      expect(role.system?).to be false
    end
  end
end
