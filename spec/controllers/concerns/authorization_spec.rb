require 'rails_helper'

RSpec.describe Authorization, type: :controller do
  # Helper to simulate user sign in
  def sign_in(user)
    session[:user_id] = user.id
    allow(controller).to receive_messages(current_user: user, user_signed_in?: true)
  end
  controller(ApplicationController) do
    include Authorization # rubocop:disable RSpec/DescribedClass

    def index
      render json: { status: 'ok' }
    end

    def admin_action
      return unless require_admin!

      render json: { status: 'admin ok' }
    end

    def moderator_action
      return unless require_moderator_or_admin!

      render json: { status: 'moderator ok' }
    end

    def authorized_action
      return unless authorize!('users.read')

      render json: { status: 'authorized' }
    end

    def resource_action
      return unless authorize_resource!('users', 'update')

      render json: { status: 'resource authorized' }
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'admin_action' => 'anonymous#admin_action'
      get 'moderator_action' => 'anonymous#moderator_action'
      get 'authorized_action' => 'anonymous#authorized_action'
      get 'resource_action' => 'anonymous#resource_action'
    end
  end

  let(:user_role) { create(:role, name: 'user') }
  let(:admin_role) { create(:role, name: 'admin') }
  let(:moderator_role) { create(:role, name: 'moderator') }
  let(:permission) { create(:permission, name: 'users.read', resource: 'users', action: 'read') }
  let(:update_permission) { create(:permission, name: 'users.update', resource: 'users', action: 'update') }

  describe '#ensure_user_has_role' do
    context 'when user is not signed in' do
      it 'does not assign a role' do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is signed in' do
      let(:user) { create(:user, :complete_registration) }

      before { sign_in(user) }

      context 'when user has no role' do
        before do
          user.update_column(:role_id, nil)
          user_role # ensure default role exists
        end

        it 'assigns default role' do
          expect(user.role).to be_nil
          get :index
          expect(user.reload.role).to eq(user_role)
        end
      end

      context 'when user already has a role' do
        before { user.update!(role: admin_role) }

        it 'does not change the role' do
          get :index
          expect(user.reload.role).to eq(admin_role)
        end
      end
    end
  end

  describe '#authorize!' do
    context 'when user is not signed in' do
      it 'redirects to dashboard with alert' do
        get :authorized_action
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq(I18n.t('authorization.access_denied'))
      end

      it 'returns forbidden for JSON requests' do
        get :authorized_action, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to include(
          'error' => I18n.t('authorization.access_denied'),
          'required_permission' => 'users.read'
        )
      end
    end

    context 'when user is signed in' do
      let(:user) { create(:user, :complete_registration) }

      before do
        sign_in(user)
        user.update!(role: user_role)
      end

      context 'without required permission' do
        it 'redirects to dashboard with alert' do
          get :authorized_action
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:alert]).to eq(I18n.t('authorization.access_denied'))
        end
      end

      context 'with required permission' do
        before { user_role.permissions << permission }

        it 'allows access' do
          get :authorized_action
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('authorized')
        end
      end
    end
  end

  describe '#authorize_resource!' do
    context 'when user is not signed in' do
      it 'redirects to dashboard' do
        get :resource_action
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is signed in' do
      let(:user) { create(:user, :complete_registration, role: user_role) }

      before { sign_in(user) }

      context 'without required permission' do
        it 'redirects to dashboard with alert' do
          get :resource_action
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:alert]).to eq(I18n.t('authorization.access_denied'))
        end

        it 'returns forbidden for JSON requests' do
          get :resource_action, format: :json
          expect(response).to have_http_status(:forbidden)
          expect(JSON.parse(response.body)['required_permission']).to eq('users.update')
        end
      end

      context 'with required permission' do
        before { user_role.permissions << update_permission }

        it 'allows access' do
          get :resource_action
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('resource authorized')
        end
      end
    end
  end

  describe '#require_admin!' do
    context 'when user is not signed in' do
      it 'redirects to dashboard' do
        get :admin_action
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is signed in' do
      let(:user) { create(:user, :complete_registration) }

      before { sign_in(user) }

      context 'as regular user' do
        before { user.update!(role: user_role) }

        it 'redirects to dashboard with alert' do
          get :admin_action
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:alert]).to eq(I18n.t('authorization.access_denied'))
        end
      end

      context 'as admin' do
        before { user.update!(role: admin_role) }

        it 'allows access' do
          get :admin_action
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('admin ok')
        end
      end
    end
  end

  describe '#require_moderator_or_admin!' do
    context 'when user is not signed in' do
      it 'redirects to dashboard' do
        get :moderator_action
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is signed in' do
      let(:user) { create(:user, :complete_registration) }

      before { sign_in(user) }

      context 'as regular user' do
        before { user.update!(role: user_role) }

        it 'redirects to dashboard with alert' do
          get :moderator_action
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:alert]).to eq(I18n.t('authorization.access_denied'))
        end
      end

      context 'as moderator' do
        before { user.update!(role: moderator_role) }

        it 'allows access' do
          get :moderator_action
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('moderator ok')
        end
      end

      context 'as admin' do
        before { user.update!(role: admin_role) }

        it 'allows access' do
          get :moderator_action
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['status']).to eq('moderator ok')
        end
      end
    end
  end

  describe 'helper methods' do
    let(:user) { create(:user, :complete_registration, role: user_role) }

    context 'when user is not signed in' do
      describe '#can?' do
        it 'returns false' do
          expect(controller.send(:can?, 'users.read')).to be false
        end
      end

      describe '#can_access?' do
        it 'returns false' do
          expect(controller.send(:can_access?, 'users', 'read')).to be false
        end
      end

      describe '#admin?' do
        it 'returns false' do
          expect(controller.send(:admin?)).to be false
        end
      end

      describe '#moderator?' do
        it 'returns false' do
          expect(controller.send(:moderator?)).to be false
        end
      end
    end

    context 'when user is signed in' do
      before { sign_in(user) }

      describe '#can?' do
        context 'without permission' do
          it 'returns false' do
            expect(controller.send(:can?, 'users.read')).to be false
          end
        end

        context 'with permission' do
          before { user_role.permissions << permission }

          it 'returns true' do
            expect(controller.send(:can?, 'users.read')).to be true
          end
        end
      end

      describe '#can_access?' do
        context 'without permission' do
          it 'returns false' do
            expect(controller.send(:can_access?, 'users', 'read')).to be false
          end
        end

        context 'with permission' do
          before { user_role.permissions << permission }

          it 'returns true' do
            expect(controller.send(:can_access?, 'users', 'read')).to be true
          end
        end
      end

      describe '#admin?' do
        context 'as regular user' do
          it 'returns false' do
            expect(controller.send(:admin?)).to be false
          end
        end

        context 'as admin' do
          before { user.update!(role: admin_role) }

          it 'returns true' do
            expect(controller.send(:admin?)).to be true
          end
        end
      end

      describe '#moderator?' do
        context 'as regular user' do
          it 'returns false' do
            expect(controller.send(:moderator?)).to be false
          end
        end

        context 'as moderator' do
          before { user.update!(role: moderator_role) }

          it 'returns true' do
            expect(controller.send(:moderator?)).to be true
          end
        end
      end
    end
  end

  describe 'view helper methods' do
    let(:user) { create(:user, :complete_registration, role: admin_role) }

    before { sign_in(user) }

    describe '#current_user_can?' do
      it 'delegates to can?' do
        expect(controller).to receive(:can?).with('users.read').and_return(true)
        expect(controller.send(:current_user_can?, 'users.read')).to be true
      end
    end

    describe '#current_user_can_access?' do
      it 'delegates to can_access?' do
        expect(controller).to receive(:can_access?).with('users', 'read').and_return(true)
        expect(controller.send(:current_user_can_access?, 'users', 'read')).to be true
      end
    end

    describe '#current_user_admin?' do
      it 'delegates to admin?' do
        expect(controller.send(:current_user_admin?)).to be true
      end
    end

    describe '#current_user_moderator?' do
      it 'delegates to moderator?' do
        expect(controller.send(:current_user_moderator?)).to be false
      end
    end

    describe 'helper method availability in views' do
      it 'makes helper methods available to views' do
        expect(controller.class._helper_methods).to include(
          :current_user_can?,
          :current_user_can_access?,
          :current_user_admin?,
          :current_user_moderator?
        )
      end
    end
  end

  describe '#handle_authorization_failure' do
    let(:user) { create(:user, :complete_registration, role: user_role) }

    before { sign_in(user) }

    context 'with HTML format' do
      it 'redirects to dashboard with localized alert' do
        get :admin_action
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq(I18n.t('authorization.access_denied'))
      end
    end

    context 'with JSON format' do
      it 'returns forbidden with error details' do
        get :admin_action, format: :json
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq(I18n.t('authorization.access_denied'))
        expect(json_response['required_permission']).to eq('admin access')
      end
    end
  end
end
