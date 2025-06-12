require 'rails_helper'

RSpec.describe Admin::RolePermissionsController, type: :controller do
  let(:admin_user) { create(:user, :complete_registration, role: create(:role, name: 'admin')) }
  let(:regular_user) { create(:user, :complete_registration, role: create(:role, name: 'user')) }
  let(:role) { create(:role, name: 'test_role', description: 'Test role') }
  let(:permission) { create(:permission, name: 'test_permission', resource: 'posts', action: 'create') }

  describe 'authentication and authorization' do
    context 'when not signed in' do
      it 'redirects to dashboard' do
        post :create, params: { role_id: role.id, id: permission.id }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when signed in as regular user' do
      before { sign_in(regular_user) }

      it 'redirects to dashboard' do
        post :create, params: { role_id: role.id, id: permission.id }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when signed in as admin' do
      before { sign_in(admin_user) }

      it 'allows access' do
        post :create, params: { role_id: role.id, id: permission.id }
        expect(response).to redirect_to(admin_role_path(role))
      end
    end
  end

  context 'when signed in as admin' do
    before { sign_in(admin_user) }

    describe 'POST #create' do
      context 'with valid parameters' do
        it 'creates a new role permission association' do
          expect do
            post :create, params: { role_id: role.id, id: permission.id }
          end.to change(RolePermission, :count).by(1)
        end

        it 'redirects to the role page with success message' do
          post :create, params: { role_id: role.id, id: permission.id }
          expect(response).to redirect_to(admin_role_path(role))
          expect(flash[:notice]).to eq('Permission was successfully added to role.')
        end

        it 'associates the permission with the role' do
          post :create, params: { role_id: role.id, id: permission.id }
          expect(role.reload.permissions).to include(permission)
        end
      end

      context 'when permission is already assigned' do
        before { role.permissions << permission }

        it 'does not create duplicate association' do
          expect do
            post :create, params: { role_id: role.id, id: permission.id }
          end.not_to change(RolePermission, :count)
        end

        it 'redirects with alert message' do
          post :create, params: { role_id: role.id, id: permission.id }
          expect(response).to redirect_to(admin_role_path(role))
          expect(flash[:alert]).to eq('Permission is already assigned to this role.')
        end
      end

      context 'with invalid role' do
        it 'raises RecordNotFound' do
          expect do
            post :create, params: { role_id: 99_999, id: permission.id }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with invalid permission' do
        it 'raises RecordNotFound' do
          expect do
            post :create, params: { role_id: role.id, id: 99_999 }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'PATCH #update' do
      let(:permission1) { create(:permission, name: 'permission1', resource: 'posts', action: 'create') }
      let(:permission2) { create(:permission, name: 'permission2', resource: 'posts', action: 'read') }
      let(:permission3) { create(:permission, name: 'permission3', resource: 'posts', action: 'update') }

      before do
        # Start with permission1 and permission2 assigned
        role.permissions = [permission1, permission2]
      end

      context 'with valid parameters' do
        it 'updates role permissions successfully' do
          patch :update, params: { role_id: role.id, permission_ids: [permission1.id, permission3.id] }
          expect(response).to redirect_to(admin_role_path(role))
          expect(flash[:notice]).to eq('Permissions updated successfully.')
        end

        it 'replaces existing permissions with new ones' do
          patch :update, params: { role_id: role.id, permission_ids: [permission1.id, permission3.id] }
          role.reload
          expect(role.permissions).to include(permission1, permission3)
          expect(role.permissions).not_to include(permission2)
        end

        it 'removes all permissions when empty array is provided' do
          patch :update, params: { role_id: role.id, permission_ids: [] }
          role.reload
          expect(role.permissions).to be_empty
        end

        it 'removes all permissions when no permission_ids parameter is provided' do
          patch :update, params: { role_id: role.id }
          role.reload
          expect(role.permissions).to be_empty
        end
      end

      context 'with invalid role' do
        it 'raises RecordNotFound' do
          expect do
            patch :update, params: { role_id: 99_999, permission_ids: [permission1.id] }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when update fails' do
        before do
          allow_any_instance_of(Role).to receive(:permission_ids=).and_raise(ActiveRecord::RecordInvalid.new(role))
        end

        it 'redirects with error message' do
          patch :update, params: { role_id: role.id, permission_ids: [permission1.id] }
          expect(response).to redirect_to(admin_role_path(role))
          expect(flash[:alert]).to match(/Failed to update permissions/)
        end
      end
    end

    describe 'DELETE #destroy' do
      let!(:role_permission) { create(:role_permission, role: role, permission: permission) }

      context 'with valid parameters' do
        it 'destroys the role permission association' do
          expect do
            delete :destroy, params: { role_id: role.id, id: permission.id }
          end.to change(RolePermission, :count).by(-1)
        end

        it 'redirects to the role page with success message' do
          delete :destroy, params: { role_id: role.id, id: permission.id }
          expect(response).to redirect_to(admin_role_path(role))
          expect(flash[:notice]).to eq('Permission was successfully removed from role.')
        end

        it 'removes the permission from the role' do
          delete :destroy, params: { role_id: role.id, id: permission.id }
          expect(role.reload.permissions).not_to include(permission)
        end
      end

      context 'when permission is not assigned to role' do
        before { role_permission.destroy }

        it 'does not change association count' do
          expect do
            delete :destroy, params: { role_id: role.id, id: permission.id }
          end.not_to change(RolePermission, :count)
        end

        it 'redirects with alert message' do
          delete :destroy, params: { role_id: role.id, id: permission.id }
          expect(response).to redirect_to(admin_role_path(role))
          expect(flash[:alert]).to eq('Permission is not assigned to this role.')
        end
      end

      context 'with invalid role' do
        it 'raises RecordNotFound' do
          expect do
            delete :destroy, params: { role_id: 99_999, id: permission.id }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with invalid permission' do
        it 'raises RecordNotFound' do
          expect do
            delete :destroy, params: { role_id: role.id, id: 99_999 }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  private

  def sign_in(user)
    session[:user_id] = user.id
    allow(controller).to receive_messages(current_user: user, user_signed_in?: true)
  end
end
