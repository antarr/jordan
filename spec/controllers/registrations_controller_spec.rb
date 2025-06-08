require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'Multi-step registration flow' do
    describe 'Step 1: Contact method selection' do
      it 'creates user with contact method and redirects to step 2' do
        expect {
          post :create, params: { contact_method: 'email' }
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.contact_method).to eq('email')
        expect(user.registration_step).to eq(1)
        expect(session[:registration_user_id]).to eq(user.id)
        expect(response).to redirect_to(registration_step_path(id: 'contact_details'))
      end

      it 'works with phone contact method' do
        post :create, params: { contact_method: 'phone' }
        
        user = User.last
        expect(user.contact_method).to eq('phone')
        expect(response).to redirect_to(registration_step_path(id: 'contact_details'))
      end
    end

    describe 'Step 2: Contact details' do
      let!(:user) { 
        user = User.new(contact_method: 'email', registration_step: 1)
        user.save!(validate: false)
        user
      }
      
      before do
        session[:registration_user_id] = user.id
      end

      it 'shows contact details form for email' do
        get :show, params: { id: 'contact_details' }
        expect(response).to render_template(:contact_details)
        expect(assigns(:user)).to eq(user)
      end

      it 'updates user with email and password' do
        patch :update, params: { 
          id: 'contact_details',
          user: { 
            email: 'test@example.com', 
            password: 'password123', 
            password_confirmation: 'password123' 
          } 
        }

        user.reload
        expect(user.email).to eq('test@example.com')
        expect(response).to redirect_to(registration_step_path(id: 'username'))
      end
    end

    describe 'Step 3: Username' do
      let!(:user) { User.create!(contact_method: 'email', email: 'test@example.com', password: 'password123', password_confirmation: 'password123', registration_step: 2) }
      
      before do
        session[:registration_user_id] = user.id
      end

      it 'shows username form' do
        get :show, params: { id: 'username' }
        expect(response).to render_template(:username)
      end

      it 'updates user with username' do
        patch :update, params: { 
          id: 'username',
          user: { username: 'testuser' } 
        }

        user.reload
        expect(user.username).to eq('testuser')
        expect(response).to redirect_to(registration_step_path(id: 'bio'))
      end
    end

    describe 'Step 4: Bio' do
      let!(:user) { User.create!(contact_method: 'email', email: 'test@example.com', password: 'password123', password_confirmation: 'password123', username: 'testuser', registration_step: 3) }
      
      before do
        session[:registration_user_id] = user.id
      end

      it 'shows bio form' do
        get :show, params: { id: 'bio' }
        expect(response).to render_template(:bio)
      end

      it 'updates user with bio' do
        bio_text = "This is my bio which is definitely more than twenty five words long because that is the minimum requirement for a valid bio in this application."
        
        patch :update, params: { 
          id: 'bio',
          user: { bio: bio_text } 
        }

        user.reload
        expect(user.bio).to eq(bio_text)
        expect(response).to redirect_to(registration_step_path(id: 'profile_photo'))
      end
    end

    describe 'Step 5: Profile photo' do
      let!(:user) { User.create!(contact_method: 'email', email: 'test@example.com', password: 'password123', password_confirmation: 'password123', username: 'testuser', bio: 'This is my bio which is definitely more than twenty five words long because that is the minimum requirement for a valid bio in this application.', registration_step: 4) }
      
      before do
        session[:registration_user_id] = user.id
      end

      it 'shows profile photo form' do
        get :show, params: { id: 'profile_photo' }
        expect(response).to render_template(:profile_photo)
      end

      it 'completes registration with profile photo' do
        expect(EmailVerificationJob).to receive(:perform_later).with(user)
        
        patch :update, params: { 
          id: 'profile_photo',
          user: { profile_photo: 'https://example.com/photo.jpg' } 
        }

        user.reload
        expect(user.profile_photo).to eq('https://example.com/photo.jpg')
        expect(user.registration_step).to eq(5)
        expect(session[:registration_user_id]).to be_nil
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq("Account created successfully! Please check your email to verify your account.")
      end

      it 'completes registration without profile photo' do
        expect(EmailVerificationJob).to receive(:perform_later).with(user)
        
        patch :update, params: { 
          id: 'profile_photo',
          user: { profile_photo: '' } 
        }

        user.reload
        expect(user.registration_step).to eq(5)
        expect(response).to redirect_to(new_session_path)
      end
    end

    describe 'Phone registration flow' do
      let!(:user) { 
        user = User.new(contact_method: 'phone', registration_step: 1)
        user.save!(validate: false)
        user
      }
      
      before do
        session[:registration_user_id] = user.id
      end

      it 'updates user with phone and password in step 2' do
        patch :update, params: { 
          id: 'contact_details',
          user: { 
            phone: '+1234567890', 
            password: 'password123', 
            password_confirmation: 'password123' 
          } 
        }

        user.reload
        expect(user.phone).to eq('+1234567890')
        expect(response).to redirect_to(registration_step_path(id: 'username'))
      end

      it 'completes registration without email verification for phone users' do
        user.update!(phone: '+1234567890', password: 'password123', password_confirmation: 'password123', username: 'phoneuser', bio: 'This is my bio which is definitely more than twenty five words long because that is the minimum requirement for a valid bio in this application.', registration_step: 4)
        
        expect(EmailVerificationJob).not_to receive(:perform_later)
        
        patch :update, params: { 
          id: 'profile_photo',
          user: { profile_photo: '' } 
        }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq("Account created successfully! You can now sign in.")
      end
    end
  end
end