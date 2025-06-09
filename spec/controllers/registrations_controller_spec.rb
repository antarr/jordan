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
end
