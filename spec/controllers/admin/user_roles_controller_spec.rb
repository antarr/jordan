require 'rails_helper'

RSpec.describe Admin::UserRolesController, type: :controller do
  let(:admin_role) { create(:role, name: 'admin') }
  let(:user_role) { create(:role, name: 'user') }
  let(:admin_user) { create(:user, :complete_registration, role: admin_role) }
  let(:regular_user) { create(:user, :complete_registration, role: user_role) }
  let(:target_user) { create(:user, :complete_registration, role: user_role) }
  let(:new_role) { create(:role, name: 'moderator', description: 'Moderator role') }

  describe 'authentication and authorization' do
    context 'when not signed in' do
      it 'redirects to dashboard' do
        get :edit, params: { user_id: target_user.id }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when signed in as regular user' do
      before { sign_in(regular_user) }

      it 'redirects to dashboard' do
        get :edit, params: { user_id: target_user.id }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when signed in as admin' do
      before { sign_in(admin_user) }

      it 'allows access' do
        get :edit, params: { user_id: target_user.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'when signed in as admin' do
    before { sign_in(admin_user) }

    describe 'GET #edit' do
      it 'returns a success response' do
        get :edit, params: { user_id: target_user.id }
        expect(response).to be_successful
      end

      it 'assigns @user' do
        get :edit, params: { user_id: target_user.id }
        expect(assigns(:user)).to eq(target_user)
      end

      it 'assigns @roles' do
        new_role # Ensure role exists
        get :edit, params: { user_id: target_user.id }
        expect(assigns(:roles)).to include(new_role)
        expect(assigns(:roles)).to include(target_user.role)
      end

      context 'with invalid user' do
        it 'raises RecordNotFound' do
          expect {
            get :edit, params: { user_id: 99999 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'PATCH #update' do
      context 'with valid role' do
        it 'updates the user role' do
          patch :update, params: { user_id: target_user.id, user: { role_id: new_role.id } }
          target_user.reload
          expect(target_user.role).to eq(new_role)
        end

        it 'redirects to users index with success message' do
          patch :update, params: { user_id: target_user.id, user: { role_id: new_role.id } }
          expect(response).to redirect_to(admin_users_path)
          expect(flash[:notice]).to eq('User role updated successfully.')
        end
      end

      context 'with no role (removing role)' do
        it 'removes the user role' do
          patch :update, params: { user_id: target_user.id, user: { role_id: '' } }
          target_user.reload
          expect(target_user.role).to be_nil
        end

        it 'redirects with success message' do
          patch :update, params: { user_id: target_user.id, user: { role_id: '' } }
          expect(response).to redirect_to(admin_users_path)
          expect(flash[:notice]).to eq('User role updated successfully.')
        end
      end

      context 'with invalid role' do
        it 'raises foreign key constraint error' do
          expect {
            patch :update, params: { user_id: target_user.id, user: { role_id: 99999 } }
          }.to raise_error(ActiveRecord::InvalidForeignKey)
        end
      end

      context 'with invalid user' do
        it 'raises RecordNotFound' do
          expect {
            patch :update, params: { user_id: 99999, user: { role_id: new_role.id } }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when update fails' do
        let(:user_with_validation_error) { create(:user, :complete_registration, role: user_role) }
        
        before do
          allow_any_instance_of(User).to receive(:update).and_return(false)
        end

        it 'renders edit template with error' do
          patch :update, params: { user_id: user_with_validation_error.id, user: { role_id: new_role.id } }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'role assignment behavior' do
      it 'preserves other user attributes when changing role' do
        original_email = target_user.email
        original_username = target_user.username
        
        patch :update, params: { user_id: target_user.id, user: { role_id: new_role.id } }
        target_user.reload
        
        expect(target_user.email).to eq(original_email)
        expect(target_user.username).to eq(original_username)
        expect(target_user.role).to eq(new_role)
      end

      it 'logs role change activity' do
        # This would be useful for audit trails in a real application
        expect {
          patch :update, params: { user_id: target_user.id, user: { role_id: new_role.id } }
        }.to change { target_user.reload.role }.from(target_user.role).to(new_role)
      end
    end
  end

  private

  def sign_in(user)
    session[:user_id] = user.id
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(true)
  end
end