require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'CurrentPassword123!',
      password_confirmation: 'CurrentPassword123!',
      email_verified_at: Time.current,
      contact_method: 'email',
      registration_step: 6,
      username: 'testuser',
      bio: 'This is a test user bio that meets the minimum length requirement'
    )
  end

  before do
    session[:user_id] = user.id
  end

  describe 'PATCH #change_password' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          password_change: {
            current_password: 'CurrentPassword123!',
            new_password: 'NewPassword123!',
            new_password_confirmation: 'NewPassword123!'
          }
        }
      end

      it 'successfully changes the password' do
        patch :change_password, params: valid_params

        user.reload
        expect(user.authenticate('NewPassword123!')).to be_truthy
        expect(user.authenticate('CurrentPassword123!')).to be_falsey
      end

      it 'redirects to edit profile path with success message' do
        patch :change_password, params: valid_params

        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:notice]).to eq('Password changed successfully')
      end
    end

    context 'with incorrect current password' do
      let(:invalid_current_password_params) do
        {
          password_change: {
            current_password: 'WrongPassword123!',
            new_password: 'NewPassword123!',
            new_password_confirmation: 'NewPassword123!'
          }
        }
      end

      it 'does not change the password' do
        patch :change_password, params: invalid_current_password_params

        user.reload
        expect(user.authenticate('CurrentPassword123!')).to be_truthy
        expect(user.authenticate('NewPassword123!')).to be_falsey
      end

      it 'renders edit template with error' do
        patch :change_password, params: invalid_current_password_params

        expect(response).to render_template(:edit)
        expect(response.status).to eq(422)
        expect(assigns(:user).errors[:current_password]).to include('is incorrect')
      end
    end

    context 'with password confirmation mismatch' do
      let(:mismatched_confirmation_params) do
        {
          password_change: {
            current_password: 'CurrentPassword123!',
            new_password: 'NewPassword123!',
            new_password_confirmation: 'DifferentPassword123!'
          }
        }
      end

      it 'does not change the password' do
        patch :change_password, params: mismatched_confirmation_params

        user.reload
        expect(user.authenticate('CurrentPassword123!')).to be_truthy
        expect(user.authenticate('NewPassword123!')).to be_falsey
      end

      it 'renders edit template with validation errors' do
        patch :change_password, params: mismatched_confirmation_params

        expect(response).to render_template(:edit)
        expect(response.status).to eq(422)
        expect(assigns(:user).errors[:password_confirmation]).to include("doesn't match Password")
      end
    end

    context 'with weak password' do
      let(:weak_password_params) do
        {
          password_change: {
            current_password: 'CurrentPassword123!',
            new_password: 'weak',
            new_password_confirmation: 'weak'
          }
        }
      end

      it 'does not change the password' do
        patch :change_password, params: weak_password_params

        user.reload
        expect(user.authenticate('CurrentPassword123!')).to be_truthy
        expect(user.authenticate('weak')).to be_falsey
      end

      it 'renders edit template with validation errors' do
        patch :change_password, params: weak_password_params

        expect(response).to render_template(:edit)
        expect(response.status).to eq(422)
        expect(assigns(:user).errors[:password]).to include('is too short (minimum is 6 characters)')
      end
    end

    context 'when not authenticated' do
      before do
        session[:user_id] = nil
      end

      it 'redirects to login' do
        patch :change_password, params: {
          password_change: {
            current_password: 'CurrentPassword123!',
            new_password: 'NewPassword123!',
            new_password_confirmation: 'NewPassword123!'
          }
        }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'with missing parameters' do
      it 'raises parameter missing error' do
        expect do
          patch :change_password, params: { other_param: 'value' }
        end.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe 'parameter filtering' do
    it 'only permits expected password change parameters' do
      controller_instance = ProfilesController.new
      controller_instance.instance_variable_set(:@user, user)

      params = ActionController::Parameters.new(
        password_change: {
          current_password: 'current',
          new_password: 'new',
          new_password_confirmation: 'confirmation',
          malicious_param: 'should_not_be_permitted'
        }
      )

      allow(controller_instance).to receive(:params).and_return(params)

      filtered_params = controller_instance.send(:password_change_params)

      expect(filtered_params.keys).to contain_exactly(
        'current_password', 'new_password', 'new_password_confirmation'
      )
      expect(filtered_params.keys).not_to include('malicious_param')
    end
  end
end
