require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin_role) { create(:role, name: 'admin') }
  let(:user_role) { create(:role, name: 'user') }
  let(:moderator_role) { create(:role, name: 'moderator') }
  let(:admin_user) { create(:user, :complete_registration, role: admin_role) }
  let(:regular_user) { create(:user, :complete_registration, role: user_role) }
  let!(:user1) { create(:user, :complete_registration, email: 'alice@example.com', username: 'alice', role: user_role) }
  let!(:user2) { create(:user, :complete_registration, email: 'bob@example.com', username: 'bob', role: moderator_role) }

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

      it 'assigns @users ordered by email' do
        get :index
        users = assigns(:users)
        expect(users).to include(user1, user2, admin_user, regular_user)
        # Check that they're ordered by email
        emails = users.map(&:email)
        expect(emails).to eq(emails.sort)
      end

      it 'includes role associations to avoid N+1 queries' do
        expect(User).to receive(:includes).with(:role).and_call_original
        get :index
      end

      it 'limits results to 50 users' do
        # Create more than 50 users
        51.times { |i| create(:user, email: "user#{i}@example.com") }
        
        get :index
        expect(assigns(:users).count).to eq(50)
      end

      context 'with search parameter' do
        it 'filters users by email' do
          get :index, params: { search: 'alice' }
          users = assigns(:users)
          expect(users).to include(user1)
          expect(users).not_to include(user2)
        end

        it 'filters users by username' do
          get :index, params: { search: 'bob' }
          users = assigns(:users)
          expect(users).to include(user2)
          expect(users).not_to include(user1)
        end

        it 'is case insensitive' do
          get :index, params: { search: 'ALICE' }
          users = assigns(:users)
          expect(users).to include(user1)
        end

        it 'searches partial matches' do
          get :index, params: { search: 'al' }
          users = assigns(:users)
          expect(users).to include(user1)
        end

        it 'returns empty results for non-matching search' do
          get :index, params: { search: 'nonexistent' }
          users = assigns(:users)
          expect(users).to be_empty
        end

        it 'ignores blank search parameter' do
          get :index, params: { search: '  ' }
          users = assigns(:users)
          expect(users).to include(user1, user2, admin_user, regular_user)
        end
      end

      context 'edge cases' do
        it 'handles users without usernames' do
          user_without_username = create(:user, email: 'nouser@example.com', username: nil)
          get :index, params: { search: 'nouser' }
          users = assigns(:users)
          expect(users).to include(user_without_username)
        end

        it 'handles users without roles' do
          user_without_role = create(:user, email: 'norole@example.com', role: nil)
          get :index
          users = assigns(:users)
          expect(users).to include(user_without_role)
        end
      end
    end

    describe 'view integration' do
      render_views

      it 'displays user information correctly' do
        get :index
        expect(response.body).to include(user1.email)
        expect(response.body).to include(user1.username)
        expect(response.body).to include(user1.role.name.humanize)
      end

      it 'displays search form' do
        get :index
        expect(response.body).to include('Search by email or username')
        expect(response.body).to include('name="search"')
      end

      it 'displays user role change links' do
        get :index
        expect(response.body).to include('Change Role')
        expect(response.body).to include(edit_admin_user_role_path(user1))
      end

      it 'shows verification status' do
        user1.update!(email_verified_at: Time.current)
        user2.update!(email_verified_at: nil)
        
        get :index
        expect(response.body).to include('Verified')
        expect(response.body).to include('Unverified')
      end
    end
  end

  describe 'account locking' do
    let(:target_user) { create(:user, :complete_registration, role: user_role) }

    context 'when signed in as admin' do
      before { sign_in(admin_user) }

      describe 'PATCH #lock' do
        it 'locks the user account' do
          patch :lock, params: { id: target_user.id }
          target_user.reload
          expect(target_user.locked?).to be true
        end

        it 'redirects with success message' do
          patch :lock, params: { id: target_user.id }
          expect(response).to redirect_to(admin_users_path)
          expect(flash[:notice]).to eq("#{target_user.email} has been locked.")
        end

        context 'when trying to lock an admin user' do
          let(:target_admin) { create(:user, :complete_registration, role: admin_role) }

          it 'prevents locking admin accounts' do
            patch :lock, params: { id: target_admin.id }
            target_admin.reload
            expect(target_admin.locked?).to be false
          end

          it 'redirects with error message' do
            patch :lock, params: { id: target_admin.id }
            expect(response).to redirect_to(admin_users_path)
            expect(flash[:alert]).to eq('Cannot lock admin accounts.')
          end
        end

        context 'when trying to lock own account' do
          it 'prevents locking own account' do
            patch :lock, params: { id: admin_user.id }
            admin_user.reload
            expect(admin_user.locked?).to be false
          end

          it 'redirects with error message' do
            patch :lock, params: { id: admin_user.id }
            expect(response).to redirect_to(admin_users_path)
            expect(flash[:alert]).to eq('Cannot lock your own account.')
          end
        end
      end

      describe 'PATCH #unlock' do
        before { target_user.lock_account! }

        it 'unlocks the user account' do
          patch :unlock, params: { id: target_user.id }
          target_user.reload
          expect(target_user.locked?).to be false
        end

        it 'redirects with success message' do
          patch :unlock, params: { id: target_user.id }
          expect(response).to redirect_to(admin_users_path)
          expect(flash[:notice]).to eq("#{target_user.email} has been unlocked.")
        end
      end
    end

    context 'when not signed in as admin' do
      before { sign_in(regular_user) }

      it 'prevents access to lock action' do
        patch :lock, params: { id: target_user.id }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'prevents access to unlock action' do
        patch :unlock, params: { id: target_user.id }
        expect(response).to redirect_to(dashboard_path)
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