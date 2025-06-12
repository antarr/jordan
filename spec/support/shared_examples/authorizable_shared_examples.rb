RSpec.shared_examples 'authorizable' do
  let(:user_role) { create(:role, name: 'test_user_role', description: 'Test user role') }
  let(:admin_role) { create(:role, name: 'admin', description: 'Admin role') }
  let(:moderator_role) { create(:role, name: 'moderator', description: 'Moderator role') }

  describe '#has_role?' do
    before { authorizable_instance.role = user_role }

    it 'returns true when user has the specified role' do
      expect(authorizable_instance.has_role?('test_user_role')).to be true
      expect(authorizable_instance.has_role?(:test_user_role)).to be true
    end

    it 'returns false when user does not have the specified role' do
      expect(authorizable_instance.has_role?('admin')).to be false
      expect(authorizable_instance.has_role?(:admin)).to be false
    end

    it 'returns false when user has no role' do
      authorizable_instance.role = nil
      expect(authorizable_instance.has_role?('user')).to be false
    end
  end

  describe '#admin?' do
    it 'returns true for admin users' do
      authorizable_instance.role = admin_role
      expect(authorizable_instance.admin?).to be true
    end

    it 'returns false for non-admin users' do
      authorizable_instance.role = user_role
      expect(authorizable_instance.admin?).to be false
    end

    it 'returns false when user has no role' do
      authorizable_instance.role = nil
      expect(authorizable_instance.admin?).to be false
    end
  end

  describe '#moderator?' do
    it 'returns true for moderator users' do
      authorizable_instance.role = moderator_role
      expect(authorizable_instance.moderator?).to be true
    end

    it 'returns false for non-moderator users' do
      authorizable_instance.role = user_role
      expect(authorizable_instance.moderator?).to be false
    end

    it 'returns false when user has no role' do
      authorizable_instance.role = nil
      expect(authorizable_instance.moderator?).to be false
    end
  end

  describe '#can?' do
    let(:permission) { create(:permission, :dashboard_access) }

    before do
      user_role.permissions << permission
      authorizable_instance.role = user_role
    end

    it 'returns true when user has the permission' do
      expect(authorizable_instance.can?(permission.name)).to be true
    end

    it 'returns false when user does not have the permission' do
      other_role = create(:role)
      authorizable_instance.role = other_role
      expect(authorizable_instance.can?(permission.name)).to be false
    end

    it 'returns false when user has no role' do
      authorizable_instance.role = nil
      expect(authorizable_instance.can?(permission.name)).to be false
    end
  end

  describe '#can_access?' do
    let(:permission) { create(:permission, resource: 'dashboard', action: 'read') }

    before do
      user_role.permissions << permission
      authorizable_instance.role = user_role
    end

    it 'returns true when user can access resource and action' do
      expect(authorizable_instance.can_access?('dashboard', 'read')).to be true
    end

    it 'returns false when user cannot access resource and action' do
      other_role = create(:role)
      authorizable_instance.role = other_role
      expect(authorizable_instance.can_access?('dashboard', 'read')).to be false
    end

    it 'returns false when user has no role' do
      authorizable_instance.role = nil
      expect(authorizable_instance.can_access?('dashboard', 'read')).to be false
    end
  end

  describe '#assign_default_role' do
    let!(:default_role) { create(:role, name: 'user') }

    it 'assigns default role when user has no role' do
      authorizable_instance.role = nil
      allow(authorizable_instance).to receive(:update!).with(role: default_role)
      authorizable_instance.assign_default_role
      expect(authorizable_instance).to have_received(:update!).with(role: default_role)
    end

    it 'does not change role when user already has one' do
      authorizable_instance.role = user_role
      expect(authorizable_instance).not_to receive(:update!)
      authorizable_instance.assign_default_role
    end

    it 'does nothing when default role does not exist' do
      default_role.destroy
      authorizable_instance.role = nil
      expect(authorizable_instance).not_to receive(:update!)
      authorizable_instance.assign_default_role
    end
  end

  describe '#role_name' do
    it 'returns role name when user has a role' do
      authorizable_instance.role = user_role
      expect(authorizable_instance.role_name).to eq('test_user_role')
    end

    it 'returns "no_role" when user has no role' do
      authorizable_instance.role = nil
      expect(authorizable_instance.role_name).to eq('no_role')
    end
  end

  describe '#permissions' do
    let(:permission) { create(:permission) }

    before do
      user_role.permissions << permission
    end

    it 'returns user permissions when user has a role' do
      authorizable_instance.role = user_role
      expect(authorizable_instance.permissions).to include(permission)
    end

    it 'returns empty relation when user has no role' do
      authorizable_instance.role = nil
      expect(authorizable_instance.permissions).to be_empty
      expect(authorizable_instance.permissions).to eq(Permission.none)
    end
  end
end
