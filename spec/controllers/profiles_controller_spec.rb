require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      username: 'testuser',
      bio: 'This is my bio that is at least 25 characters long',
      contact_method: 'email',
      registration_step: 6,
      email_verified_at: Time.current
    )
  end

  describe 'authentication' do
    describe 'GET #edit' do
      context 'when not authenticated' do
        it 'redirects to login page' do
          get :edit
          expect(response).to redirect_to(new_session_path)
        end
      end
    end

    describe 'PATCH #update' do
      context 'when not authenticated' do
        it 'redirects to login page' do
          patch :update, params: { user: { bio: 'New bio' } }
          expect(response).to redirect_to(new_session_path)
        end
      end
    end
  end

  describe 'authenticated user' do
    before do
      session[:user_id] = user.id
    end

    describe 'GET #edit' do
      it 'returns success' do
        get :edit
        expect(response).to have_http_status(:success)
      end

      it 'renders the edit template' do
        get :edit
        expect(response).to render_template(:edit)
      end

      it 'assigns current user to @user' do
        get :edit
        expect(assigns(:user)).to eq(user)
      end
    end

    describe 'PATCH #update' do
      context 'with valid parameters' do
        let(:valid_params) do
          {
            user: {
              bio: 'This is my updated bio that meets the minimum length requirement',
              username: 'newusername',
              location_name: 'San Francisco, CA',
              latitude: '37.7749',
              longitude: '-122.4194',
              location_private: 'true'
            }
          }
        end

        it 'updates the user profile' do
          patch :update, params: valid_params
          user.reload
          expect(user.bio).to eq('This is my updated bio that meets the minimum length requirement')
          expect(user.username).to eq('newusername')
          expect(user.location_name).to eq('San Francisco, CA')
          expect(user.latitude).to eq(37.7749)
          expect(user.longitude).to eq(-122.4194)
          expect(user.location_private).to be true
        end

        it 'redirects to edit profile page' do
          patch :update, params: valid_params
          expect(response).to redirect_to(edit_profile_path)
        end

        it 'sets a success notice' do
          patch :update, params: valid_params
          expect(flash[:notice]).to eq(I18n.t('profiles.update.success'))
        end

        context 'with profile photo upload' do
          it 'attaches the profile photo' do
            file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'test_image.jpg'), 'image/jpeg')

            patch :update, params: {
              user: {
                profile_photo: file
              }
            }

            user.reload
            expect(user.profile_photo).to be_attached
          end
        end

        context 'updating only specific fields' do
          it 'updates only bio' do
            original_username = user.username

            patch :update, params: {
              user: { bio: 'Just updating my bio to something longer than 25 characters' }
            }

            user.reload
            expect(user.bio).to eq('Just updating my bio to something longer than 25 characters')
            expect(user.username).to eq(original_username)
          end

          it 'updates only location' do
            original_bio = user.bio

            patch :update, params: {
              user: {
                latitude: '40.7128',
                longitude: '-74.0060',
                location_name: 'New York, NY'
              }
            }

            user.reload
            expect(user.latitude).to eq(40.7128)
            expect(user.longitude).to eq(-74.0060)
            expect(user.location_name).to eq('New York, NY')
            expect(user.bio).to eq(original_bio)
          end

          it 'can clear location' do
            user.update!(
              latitude: 37.7749,
              longitude: -122.4194,
              location_name: 'San Francisco, CA'
            )

            patch :update, params: {
              user: {
                latitude: '',
                longitude: '',
                location_name: ''
              }
            }

            user.reload
            expect(user.latitude).to be_nil
            expect(user.longitude).to be_nil
            expect(user.location_name).to be_blank
          end

          it 'updates location privacy setting' do
            patch :update, params: {
              user: { location_private: 'false' }
            }

            user.reload
            expect(user.location_private).to be false
          end
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            user: {
              bio: 'Too short', # Less than 25 characters
              username: 'invalid@username!' # Contains invalid characters
            }
          }
        end

        it 'does not update the user' do
          original_bio = user.bio
          original_username = user.username

          patch :update, params: invalid_params

          user.reload
          expect(user.bio).to eq(original_bio)
          expect(user.username).to eq(original_username)
        end

        it 'renders the edit template' do
          patch :update, params: invalid_params
          expect(response).to render_template(:edit)
        end

        it 'returns unprocessable entity status' do
          patch :update, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'assigns user with errors' do
          patch :update, params: invalid_params
          expect(assigns(:user).errors).not_to be_empty
        end

        context 'specific validation errors' do
          it 'shows error for short bio' do
            patch :update, params: { user: { bio: 'Short' } }
            expect(assigns(:user).errors[:bio]).to include('is too short (minimum is 25 characters)')
          end

          it 'shows error for invalid username format' do
            patch :update, params: { user: { username: 'user@name' } }
            expect(assigns(:user).errors[:username]).to include('can only contain letters, numbers, and underscores')
          end

          it 'shows error for duplicate username' do
            User.create!(
              email: 'other@example.com',
              password: 'Password123!',
              password_confirmation: 'Password123!',
              username: 'taken',
              bio: 'Another user bio that is at least 25 characters long',
              contact_method: 'email',
              registration_step: 6
            )

            patch :update, params: { user: { username: 'taken' } }
            expect(assigns(:user).errors[:username]).to include('has already been taken')
          end

          it 'shows error for invalid email format' do
            patch :update, params: { user: { email: 'invalid-email' } }
            expect(assigns(:user).errors[:email]).to include('is not a valid email address')
          end

          it 'shows error for duplicate email' do
            User.create!(
              email: 'taken@example.com',
              password: 'Password123!',
              password_confirmation: 'Password123!',
              username: 'otheruser',
              bio: 'Another user bio that is at least 25 characters long',
              contact_method: 'email',
              registration_step: 6
            )

            patch :update, params: { user: { email: 'taken@example.com' } }
            expect(assigns(:user).errors[:email]).to include('has already been taken')
          end

          it 'shows error for invalid latitude' do
            patch :update, params: { user: { latitude: '91' } }
            expect(assigns(:user).errors[:latitude]).to include('must be less than or equal to 90')
          end

          it 'shows error for invalid longitude' do
            patch :update, params: { user: { longitude: '181' } }
            expect(assigns(:user).errors[:longitude]).to include('must be less than or equal to 180')
          end

          it 'shows error when only latitude is provided' do
            patch :update, params: { user: { latitude: '40.7128', longitude: '' } }
            expect(assigns(:user).errors[:longitude]).to include("can't be blank")
          end

          it 'shows error when only longitude is provided' do
            patch :update, params: { user: { latitude: '', longitude: '-74.0060' } }
            expect(assigns(:user).errors[:latitude]).to include("can't be blank")
          end
        end
      end

      context 'parameter filtering' do
        it 'does not allow updating password' do
          patch :update, params: {
            user: {
              password: 'NewPassword123!',
              password_confirmation: 'NewPassword123!'
            }
          }

          user.reload
          expect(user.authenticate('Password123!')).to be_truthy
          expect(user.authenticate('NewPassword123!')).to be_falsey
        end

        it 'does not allow updating email_verified_at' do
          user.update!(email_verified_at: nil)

          patch :update, params: {
            user: { email_verified_at: Time.current }
          }

          user.reload
          expect(user.email_verified_at).to be_nil
        end

        it 'does not allow updating registration_step' do
          original_step = user.registration_step

          patch :update, params: {
            user: { registration_step: 1 }
          }

          user.reload
          expect(user.registration_step).to eq(original_step)
        end

        it 'does not allow updating contact_method' do
          patch :update, params: {
            user: { contact_method: 'phone' }
          }

          user.reload
          expect(user.contact_method).to eq('email')
        end
      end
    end
  end

  describe 'edge cases' do
    before do
      session[:user_id] = user.id
    end

    it 'handles missing user params gracefully' do
      expect do
        patch :update, params: {}
      end.to raise_error(ActionController::ParameterMissing)
    end

    it 'handles user params with no permitted attributes' do
      # When all submitted attributes are not permitted, the filtered params become empty
      patch :update, params: { user: { not_permitted: 'value' } }
      expect(response).to redirect_to(edit_profile_path)
    end

    it 'maintains user session after update' do
      patch :update, params: {
        user: { bio: 'Updated bio that is definitely longer than 25 characters' }
      }

      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe 'DELETE #remove_photo' do
    before do
      session[:user_id] = user.id
    end

    context 'when user has a profile photo' do
      before do
        # Create a mock file and attach it
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'test_image.jpg'), 'image/jpeg')
        user.profile_photo.attach(file)
      end

      it 'removes the profile photo' do
        expect do
          delete :remove_photo
        end.to change { user.reload.profile_photo.attached? }.from(true).to(false)
      end

      it 'redirects to edit profile page' do
        delete :remove_photo
        expect(response).to redirect_to(edit_profile_path)
      end

      it 'sets a success notice' do
        delete :remove_photo
        expect(flash[:notice]).to eq(I18n.t('profiles.remove_photo.success'))
      end
    end

    context 'when user has no profile photo' do
      it 'does not change anything' do
        expect do
          delete :remove_photo
        end.not_to(change { user.reload.profile_photo.attached? })
      end

      it 'redirects to edit profile page' do
        delete :remove_photo
        expect(response).to redirect_to(edit_profile_path)
      end

      it 'sets an alert message' do
        delete :remove_photo
        expect(flash[:alert]).to eq(I18n.t('profiles.remove_photo.no_photo'))
      end
    end

    context 'when not authenticated' do
      before do
        session[:user_id] = nil
      end

      it 'redirects to login page' do
        delete :remove_photo
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe 'internationalization' do
    before do
      session[:user_id] = user.id
    end

    it 'uses the correct locale for success message' do
      patch :update, params: {
        locale: 'es',
        user: { bio: 'Bio actualizada con más de veinticinco caracteres' }
      }

      expect(flash[:notice]).to eq('Perfil actualizado exitosamente')
    end
  end
end
