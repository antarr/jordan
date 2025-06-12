require 'rails_helper'

RSpec.describe RolePermission, type: :model do
  let(:role) { create(:role) }
  let(:permission) { create(:permission) }

  describe 'associations' do
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:permission) }
  end

  describe 'validations' do
    subject { build(:role_permission, role: role, permission: permission) }

    it { is_expected.to validate_uniqueness_of(:role_id).scoped_to(:permission_id) }

    it 'prevents duplicate role-permission combinations' do
      create(:role_permission, role: role, permission: permission)
      duplicate = build(:role_permission, role: role, permission: permission)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:role_id]).to include('has already been taken')
    end

    it 'allows same role with different permissions' do
      permission2 = create(:permission)
      create(:role_permission, role: role, permission: permission)
      different_permission = build(:role_permission, role: role, permission: permission2)

      expect(different_permission).to be_valid
    end

    it 'allows same permission with different roles' do
      role2 = create(:role)
      create(:role_permission, role: role, permission: permission)
      different_role = build(:role_permission, role: role2, permission: permission)

      expect(different_role).to be_valid
    end
  end

  describe 'creation and associations' do
    it 'creates valid role-permission association' do
      role_permission = create(:role_permission, role: role, permission: permission)

      expect(role_permission).to be_valid
      expect(role_permission.role).to eq(role)
      expect(role_permission.permission).to eq(permission)
    end

    it 'allows role to have multiple permissions' do
      permission1 = create(:permission, resource: 'users', action: 'read')
      permission2 = create(:permission, resource: 'users', action: 'create')

      create(:role_permission, role: role, permission: permission1)
      create(:role_permission, role: role, permission: permission2)

      expect(role.reload.permissions).to include(permission1, permission2)
      expect(role.permissions.count).to eq(2)
    end

    it 'allows permission to be assigned to multiple roles' do
      role1 = create(:role, name: 'admin')
      role2 = create(:role, name: 'moderator')

      create(:role_permission, role: role1, permission: permission)
      create(:role_permission, role: role2, permission: permission)

      expect(permission.reload.roles).to include(role1, role2)
      expect(permission.roles.count).to eq(2)
    end
  end

  describe 'deletion behavior' do
    it 'is destroyed when role is destroyed' do
      role_permission = create(:role_permission, role: role, permission: permission)
      role_permission_id = role_permission.id

      role.destroy

      expect(described_class.find_by(id: role_permission_id)).to be_nil
    end

    it 'is destroyed when permission is destroyed' do
      role_permission = create(:role_permission, role: role, permission: permission)
      role_permission_id = role_permission.id

      permission.destroy

      expect(described_class.find_by(id: role_permission_id)).to be_nil
    end
  end
end
