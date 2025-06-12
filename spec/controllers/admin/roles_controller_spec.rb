require 'rails_helper'

RSpec.describe Admin::RolesController, type: :controller do
  let(:admin_user) { create(:user, :complete_registration, role: create(:role, name: 'admin')) }
  let(:regular_user) { create(:user, :complete_registration, role: create(:role, name: 'user')) }
  let(:role) { create(:role, name: 'test_role', description: 'Test role') }

  describe 'authentication and authorization' do
    context 'when not signed in' do
      it 'redirects to dashboard' do
        get :index
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when signed in as regular user' do
      before { sign_in(regular_user) }

      it 'redirects to dashboard' do
        get :index
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when signed in as admin' do
      before { sign_in(admin_user) }

      it 'allows access' do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'when signed in as admin' do
    before { sign_in(admin_user) }

    describe 'GET #index' do
      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns @roles' do
        role
        get :index
        expect(assigns(:roles)).to include(role)
      end
    end

    describe 'GET #show' do
      it 'returns a success response' do
        get :show, params: { id: role.id }
        expect(response).to be_successful
      end

      it 'assigns @role' do
        get :show, params: { id: role.id }
        expect(assigns(:role)).to eq(role)
      end
    end

    describe 'GET #new' do
      it 'returns a success response' do
        get :new
        expect(response).to be_successful
      end

      it 'assigns a new role' do
        get :new
        expect(assigns(:role)).to be_a_new(Role)
      end
    end

    describe 'POST #create' do
      context 'with valid parameters' do
        let(:valid_attributes) { { name: 'editor', description: 'Content editor role' } }

        it 'creates a new Role' do
          expect do
            post :create, params: { role: valid_attributes }
          end.to change(Role, :count).by(1)
        end

        it 'redirects to the roles index' do
          post :create, params: { role: valid_attributes }
          expect(response).to redirect_to(admin_roles_path)
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) { { name: '', description: '' } }

        it 'does not create a new Role' do
          expect do
            post :create, params: { role: invalid_attributes }
          end.not_to change(Role, :count)
        end

        it 'returns a success response (to display the form with errors)' do
          post :create, params: { role: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'GET #edit' do
      it 'returns a success response' do
        get :edit, params: { id: role.id }
        expect(response).to be_successful
      end
    end

    describe 'PATCH #update' do
      context 'with valid parameters' do
        let(:new_attributes) { { description: 'Updated description' } }

        it 'updates the requested role' do
          patch :update, params: { id: role.id, role: new_attributes }
          role.reload
          expect(role.description).to eq('Updated description')
        end

        it 'redirects to the roles index' do
          patch :update, params: { id: role.id, role: new_attributes }
          expect(response).to redirect_to(admin_roles_path)
        end
      end

      context 'with invalid parameters' do
        it 'returns a success response (to display the form with errors)' do
          patch :update, params: { id: role.id, role: { name: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'DELETE #destroy' do
      let!(:role_to_delete) { create(:role, name: 'deletable', system_role: false) }

      context 'with custom role' do
        context 'with no assigned users' do
          it 'destroys the requested role' do
            expect do
              delete :destroy, params: { id: role_to_delete.id }
            end.to change(Role, :count).by(-1)
          end

          it 'redirects to the roles list' do
            delete :destroy, params: { id: role_to_delete.id }
            expect(response).to redirect_to(admin_roles_path)
          end
        end

        context 'with assigned users' do
          before { create(:user, role: role_to_delete) }

          it 'does not destroy the role' do
            expect do
              delete :destroy, params: { id: role_to_delete.id }
            end.not_to change(Role, :count)
          end

          it 'redirects with error message' do
            delete :destroy, params: { id: role_to_delete.id }
            expect(response).to redirect_to(admin_roles_path)
            expect(flash[:alert]).to eq('Cannot delete role with assigned users.')
          end
        end
      end

      context 'with system role' do
        let!(:system_role) { create(:role, name: 'system', system_role: true) }

        it 'does not destroy the role' do
          expect do
            delete :destroy, params: { id: system_role.id }
          end.not_to change(Role, :count)
        end

        it 'redirects with error message' do
          delete :destroy, params: { id: system_role.id }
          expect(response).to redirect_to(admin_roles_path)
          expect(flash[:alert]).to eq('System roles cannot be deleted.')
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
