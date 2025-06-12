require 'rails_helper'

RSpec.describe AccountUnlocksController, type: :controller do
  describe 'when not signed in' do
    describe 'GET #new' do
      it 'returns a success response' do
        get :new
        expect(response).to be_successful
      end
    end

    describe 'POST #create' do
      let!(:auto_locked_user) { create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: false) }
      let!(:admin_locked_user) { create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: true) }
      let!(:unlocked_user) { create(:user, :complete_registration) }

      it 'sends unlock email for auto-locked user' do
        expect do
          post :create, params: { email: auto_locked_user.email }
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('account_unlocks.create.sent'))
      end

      it 'does not send email for admin-locked user but shows same message' do
        expect do
          post :create, params: { email: admin_locked_user.email }
        end.not_to(change { ActionMailer::Base.deliveries.count })

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('account_unlocks.create.sent'))
      end

      it 'does not send email for unlocked user but shows same message' do
        expect do
          post :create, params: { email: unlocked_user.email }
        end.not_to(change { ActionMailer::Base.deliveries.count })

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('account_unlocks.create.sent'))
      end

      it 'does not send email for non-existent user but shows same message' do
        expect do
          post :create, params: { email: 'nonexistent@example.com' }
        end.not_to(change { ActionMailer::Base.deliveries.count })

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('account_unlocks.create.sent'))
      end
    end

    describe 'GET #unlock' do
      let!(:auto_locked_user) do
        create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: false,
                                              auto_unlock_token: 'valid_token')
      end
      let!(:admin_locked_user) do
        create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: true,
                                              auto_unlock_token: 'admin_token')
      end

      it 'unlocks auto-locked user with valid token' do
        get :unlock, params: { token: 'valid_token' }

        auto_locked_user.reload
        expect(auto_locked_user.locked?).to be false
        expect(auto_locked_user.auto_unlock_token).to be_nil
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t('account_unlocks.unlock.success'))
      end

      it 'does not unlock admin-locked user' do
        get :unlock, params: { token: 'admin_token' }

        admin_locked_user.reload
        expect(admin_locked_user.locked?).to be true
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('account_unlocks.unlock.invalid_token'))
      end

      it 'does not unlock with invalid token' do
        get :unlock, params: { token: 'invalid_token' }

        auto_locked_user.reload
        expect(auto_locked_user.locked?).to be true
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('account_unlocks.unlock.invalid_token'))
      end
    end
  end

  describe 'when signed in' do
    let(:user) { create(:user, :complete_registration) }

    before { sign_in(user) }

    it 'redirects to dashboard for new action' do
      get :new
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects to dashboard for create action' do
      post :create, params: { email: 'test@example.com' }
      expect(response).to redirect_to(dashboard_path)
    end
  end

  private

  def sign_in(user)
    session[:user_id] = user.id
    allow(controller).to receive_messages(current_user: user, user_signed_in?: true)
  end
end
