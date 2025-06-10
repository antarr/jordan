require 'rails_helper'

RSpec.describe SessionsController, 'auto-lock notifications', type: :controller do
  let(:user) { create(:user, :complete_registration) }

  describe 'POST #create with email login' do
    context 'when account gets locked on this attempt' do
      before do
        # Make 4 failed attempts (one away from locking)
        user.update!(failed_login_attempts: 4)
      end

      it 'shows account just locked message' do
        post :create, params: { 
          login_type: 'email',
          email: user.email, 
          password: 'wrong_password' 
        }

        expect(flash.now[:alert]).to eq(I18n.t('controllers.sessions.create.account_just_locked'))
        expect(response).to render_template(:new)
      end

      it 'sends email notification' do
        expect {
          post :create, params: { 
            login_type: 'email',
            email: user.email, 
            password: 'wrong_password' 
          }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'locks the account' do
        post :create, params: { 
          login_type: 'email',
          email: user.email, 
          password: 'wrong_password' 
        }

        user.reload
        expect(user.locked?).to be true
        expect(user.auto_locked?).to be true
      end
    end

    context 'when account does not get locked on this attempt' do
      before do
        # Make only 2 failed attempts (still safe)
        user.update!(failed_login_attempts: 2)
      end

      it 'shows normal invalid credentials message' do
        post :create, params: { 
          login_type: 'email',
          email: user.email, 
          password: 'wrong_password' 
        }

        expect(flash.now[:alert]).to eq(I18n.t('controllers.sessions.create.invalid_credentials'))
      end

      it 'does not send email notification' do
        expect {
          post :create, params: { 
            login_type: 'email',
            email: user.email, 
            password: 'wrong_password' 
          }
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when account was already locked' do
      before do
        user.lock_account!
      end

      it 'shows already locked message for auto-locked account' do
        post :create, params: { 
          login_type: 'email',
          email: user.email, 
          password: user.password 
        }

        expect(flash[:alert]).to eq(I18n.t('controllers.sessions.create.account_auto_locked'))
        expect(response).to redirect_to(new_session_path)
      end

      it 'shows admin locked message for admin-locked account' do
        user.update!(locked_by_admin: true)
        
        post :create, params: { 
          login_type: 'email',
          email: user.email, 
          password: user.password 
        }

        expect(flash[:alert]).to eq(I18n.t('controllers.sessions.create.account_locked'))
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe 'POST #create with phone login' do
    let(:phone_user) { create(:user, :complete_registration, contact_method: 'phone', phone: '+1234567890') }

    before do
      phone_user.verify_phone!
    end

    context 'when account gets locked on this attempt' do
      before do
        phone_user.update!(failed_login_attempts: 4)
      end

      it 'shows account just locked message' do
        post :create, params: { 
          login_type: 'phone',
          phone: phone_user.phone, 
          password: 'wrong_password' 
        }

        expect(flash.now[:alert]).to eq(I18n.t('phone_sessions.create.account_just_locked'))
        expect(response).to render_template(:new)
      end

      it 'sends email notification if user has email' do
        expect {
          post :create, params: { 
            login_type: 'phone',
            phone: phone_user.phone, 
            password: 'wrong_password' 
          }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end