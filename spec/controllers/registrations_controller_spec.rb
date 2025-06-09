require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'Multi-step registration flow' do
    describe 'Step 1: Contact method selection' do
      it 'creates user with contact method and redirects to step 2' do
        expect do
          post :create, params: { contact_method: 'email' }
        end.to change(User, :count).by(1)

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
      let!(:user) { create(:user, :step_one, contact_method: 'email') }

      before do
        session[:registration_user_id] = user.id
      end

      it 'shows contact details form for email' do
        get :show, params: { id: 'contact_details' }
        expect(response).to render_template(:contact_details)
        expect(assigns(:user)).to eq(user)
      end

      it 'updates user with email and password' do
        email = Faker::Internet.email
        password = Faker::Internet.password(min_length: 6)

        patch :update, params: {
          id: 'contact_details',
          user: {
            email: email,
            password: password,
            password_confirmation: password
          }
        }

        user.reload
        expect(user.email).to eq(email.downcase)
        expect(response).to redirect_to(registration_step_path(id: 'username'))
      end
    end

    describe 'Step 3: Username' do
      let!(:user) { create(:user, :email_user, :step_two) }

      before do
        session[:registration_user_id] = user.id
      end

      it 'shows username form' do
        get :show, params: { id: 'username' }
        expect(response).to render_template(:username)
      end

      it 'updates user with username' do
        username = Faker::Internet.username(specifier: 5..12, separators: %w[_]).gsub(/[^a-zA-Z0-9_]/, '_')

        patch :update, params: {
          id: 'username',
          user: { username: username }
        }

        user.reload
        expect(user.username).to eq(username)
        expect(response).to redirect_to(registration_step_path(id: 'bio'))
      end
    end

    describe 'Step 4: Bio' do
      let!(:user) do
        create(:user, :email_user, :step_three,
               username: Faker::Internet.username(specifier: 5..12, separators: %w[_]).gsub(/[^a-zA-Z0-9_]/, '_'))
      end

      before do
        session[:registration_user_id] = user.id
      end

      it 'shows bio form' do
        get :show, params: { id: 'bio' }
        expect(response).to render_template(:bio)
      end

      it 'updates user with bio' do
        bio_text = Faker::Lorem.paragraph(sentence_count: 3, supplemental: true, random_sentences_to_add: 2)

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
      let!(:user) do
        create(:user, :email_user, :step_four,
               username: Faker::Internet.username(specifier: 5..12, separators: %w[_]).gsub(/[^a-zA-Z0-9_]/, '_'), bio: Faker::Lorem.paragraph(sentence_count: 3))
      end

      before do
        session[:registration_user_id] = user.id
      end

      it 'shows profile photo form' do
        get :show, params: { id: 'profile_photo' }
        expect(response).to render_template(:profile_photo)
      end

      it 'completes registration with profile photo' do
        expect(EmailVerificationJob).to receive(:perform_later).with(user)
        photo_url = Faker::Internet.url(host: 'example.com', path: '/photo.jpg')

        patch :update, params: {
          id: 'profile_photo',
          user: { profile_photo: photo_url }
        }

        user.reload
        expect(user.profile_photo).to eq(photo_url)
        expect(user.registration_step).to eq(5)
        expect(session[:registration_user_id]).to be_nil
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq('Account created successfully! Please check your email to verify your account.')
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
      let!(:user) { create(:user, :step_one, contact_method: 'phone') }

      before do
        session[:registration_user_id] = user.id
      end

      it 'updates user with phone and password in step 2' do
        phone = Faker::PhoneNumber.cell_phone_in_e164
        password = Faker::Internet.password(min_length: 6)

        patch :update, params: {
          id: 'contact_details',
          user: {
            phone: phone,
            password: password,
            password_confirmation: password
          }
        }

        user.reload
        expect(user.phone).to eq(phone)
        expect(response).to redirect_to(registration_step_path(id: 'username'))
      end

      it 'completes registration without email verification for phone users' do
        phone = Faker::PhoneNumber.cell_phone_in_e164
        password = Faker::Internet.password(min_length: 6)
        username = Faker::Internet.username(specifier: 5..12, separators: %w[_]).gsub(/[^a-zA-Z0-9_]/, '_')
        bio = Faker::Lorem.paragraph(sentence_count: 3)

        user.update!(phone: phone, password: password, password_confirmation: password, username: username, bio: bio,
                     registration_step: 4)

        expect(EmailVerificationJob).not_to receive(:perform_later)

        patch :update, params: {
          id: 'profile_photo',
          user: { profile_photo: '' }
        }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq('Account created successfully! You can now sign in.')
      end
    end
  end

  describe 'Error handling and edge cases' do
    describe 'POST #create' do
      it 'renders new template with error when contact_method is missing' do
        post :create, params: {}
        
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to be_present
        expect(User.count).to eq(0)
      end

      it 'renders new template with error when contact_method is blank' do
        post :create, params: { contact_method: '' }
        
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to be_present
        expect(User.count).to eq(0)
      end

      it 'handles user save failure gracefully' do
        allow_any_instance_of(User).to receive(:save).and_return(false)
        
        post :create, params: { contact_method: 'email' }
        
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'GET #show' do
      it 'redirects to new registration when no user in session' do
        get :show, params: { id: 'contact_details' }
        
        expect(response).to redirect_to(new_registration_path)
      end

      it 'redirects when session user does not exist' do
        session[:registration_user_id] = 999999
        
        get :show, params: { id: 'contact_details' }
        
        expect(response).to redirect_to(new_registration_path)
      end

      it 'assigns step_number and total_steps' do
        user = create(:user, :step_one)
        session[:registration_user_id] = user.id

        get :show, params: { id: 'contact_details' }
        
        expect(assigns(:step_number)).to eq(2)
        expect(assigns(:total_steps)).to eq(4)
      end
    end

    describe 'PATCH #update' do
      let(:user) { create(:user, :step_one, contact_method: 'email') }

      before do
        session[:registration_user_id] = user.id
      end

      context 'when validation fails' do
        it 'renders wizard template for contact_details step with invalid data' do
          patch :update, params: {
            id: 'contact_details',
            user: {
              email: 'invalid-email',
              password: 'short',
              password_confirmation: 'different'
            }
          }

          expect(response).to render_template(:contact_details)
          expect(user.reload.registration_step).to eq(1)
        end

        it 'renders wizard template for username step with invalid data' do
          user.update!(registration_step: 2, email: 'test@example.com')
          
          patch :update, params: {
            id: 'username',
            user: { username: 'invalid@username!' }
          }

          expect(response).to render_template(:username)
          expect(user.reload.registration_step).to eq(2)
        end

        it 'renders wizard template for bio step with invalid data' do
          user.update_columns(registration_step: 3)
          allow(user).to receive(:save).and_return(false)
          allow(User).to receive(:find_by).and_return(user)
          
          patch :update, params: {
            id: 'bio',
            user: { bio: 'too short' }
          }

          expect(response).to render_template(:bio)
        end

        it 'renders wizard template for profile_photo step with invalid data' do
          user.update_columns(registration_step: 4)
          allow(user).to receive(:save).and_return(false)
          allow(User).to receive(:find_by).and_return(user)
          
          patch :update, params: {
            id: 'profile_photo',
            user: { profile_photo: 'test.jpg' }
          }

          expect(response).to render_template(:profile_photo)
        end
      end

      context 'email verification token generation' do
        it 'generates email verification token for email users without existing token' do
          user.update!(registration_step: 1, email_verification_token: nil)
          
          patch :update, params: {
            id: 'contact_details',
            user: {
              email: 'test@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }

          user.reload
          expect(user.email_verification_token).to be_present
        end

        it 'does not generate new token if one already exists' do
          user.update!(registration_step: 1, email_verification_token: 'existing_token')
          
          patch :update, params: {
            id: 'contact_details',
            user: {
              email: 'test@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }

          user.reload
          expect(user.email_verification_token).to eq('existing_token')
        end
      end
    end
  end

  describe 'Feature flags' do
    describe 'Phone registration feature flag' do
      context 'when phone registration is enabled' do
        before do
          allow(Rails.application.config).to receive(:features).and_return({ phone_registration_enabled: true })
        end

        it 'allows phone registration' do
          post :create, params: { contact_method: 'phone' }
          
          user = User.last
          expect(user.contact_method).to eq('phone')
          expect(response).to redirect_to(registration_step_path(id: 'contact_details'))
        end

        it 'allows access to phone registration steps' do
          user = create(:user, :step_one, contact_method: 'phone')
          session[:registration_user_id] = user.id

          get :show, params: { id: 'contact_details' }
          expect(response).to render_template(:contact_details)
        end
      end

      context 'when phone registration is disabled' do
        before do
          allow(Rails.application.config).to receive(:features).and_return({ phone_registration_enabled: false })
        end

        it 'redirects phone registration creation to new registration path' do
          post :create, params: { contact_method: 'phone' }
          
          expect(response).to redirect_to(new_registration_path)
          expect(flash[:alert]).to eq('Phone registration is currently unavailable. Please use email registration instead.')
          expect(User.count).to eq(0)
        end

        it 'redirects existing phone registration steps to new registration path' do
          user = create(:user, :step_one, contact_method: 'phone')
          session[:registration_user_id] = user.id

          get :show, params: { id: 'contact_details' }
          expect(response).to redirect_to(new_registration_path)
          expect(flash[:alert]).to eq('Phone registration is currently unavailable. Please use email registration instead.')
        end

        it 'redirects phone registration updates to new registration path' do
          user = create(:user, :step_one, contact_method: 'phone')
          session[:registration_user_id] = user.id

          patch :update, params: {
            id: 'contact_details',
            user: {
              phone: '+1234567890',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }

          expect(response).to redirect_to(new_registration_path)
          expect(flash[:alert]).to eq('Phone registration is currently unavailable. Please use email registration instead.')
        end

        it 'allows email registration when phone registration is disabled' do
          post :create, params: { contact_method: 'email' }
          
          user = User.last
          expect(user.contact_method).to eq('email')
          expect(response).to redirect_to(registration_step_path(id: 'contact_details'))
        end
      end
    end
  end

  describe 'Helper methods' do
    let(:controller) { described_class.new }

    describe '#step_number' do
      it 'returns correct step numbers for each step' do
        expect(controller.send(:step_number)).to eq(1) # default
        
        allow(controller).to receive(:step).and_return(:contact_details)
        expect(controller.send(:step_number)).to eq(2)
        
        allow(controller).to receive(:step).and_return(:username)
        expect(controller.send(:step_number)).to eq(3)
        
        allow(controller).to receive(:step).and_return(:bio)
        expect(controller.send(:step_number)).to eq(4)
        
        allow(controller).to receive(:step).and_return(:profile_photo)
        expect(controller.send(:step_number)).to eq(5)
      end
    end

    describe '#step_name' do
      it 'returns correct step names for each step' do
        expect(controller.send(:step_name)).to eq('Getting Started') # default
        
        allow(controller).to receive(:step).and_return(:contact_details)
        expect(controller.send(:step_name)).to eq('Contact Details')
        
        allow(controller).to receive(:step).and_return(:username)
        expect(controller.send(:step_name)).to eq('Username')
        
        allow(controller).to receive(:step).and_return(:bio)
        expect(controller.send(:step_name)).to eq('Bio')
        
        allow(controller).to receive(:step).and_return(:profile_photo)
        expect(controller.send(:step_name)).to eq('Profile Photo')
      end
    end

    describe '#contact_details_params' do
      let(:user) { create(:user, :step_one) }
      
      before do
        allow(controller).to receive(:current_user_registration).and_return(user)
      end

      it 'permits email params for email users' do
        user.update!(contact_method: 'email')
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(
            user: { email: 'test@example.com', password: 'password', password_confirmation: 'password', phone: 'should_not_be_permitted' }
          )
        )
        
        result = controller.send(:contact_details_params)
        expect(result.keys).to include('email', 'password', 'password_confirmation')
        expect(result.keys).not_to include('phone')
      end

      it 'permits phone params for phone users' do
        user.update!(contact_method: 'phone')
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(
            user: { phone: '+1234567890', password: 'password', password_confirmation: 'password', email: 'should_not_be_permitted' }
          )
        )
        
        result = controller.send(:contact_details_params)
        expect(result.keys).to include('phone', 'password', 'password_confirmation')
        expect(result.keys).not_to include('email')
      end
    end
  end
end
