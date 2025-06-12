require 'rails_helper'

RSpec.describe WebauthnCredentialsController, type: :controller do
  let(:user) { create(:user) }
  let(:webauthn_credential) { create(:webauthn_credential, user: user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:require_authentication).and_return(true)
  end

  describe 'GET #index' do
    it 'returns user credentials ordered by creation date' do
      older_credential = create(:webauthn_credential, user: user, created_at: 1.day.ago)
      newer_credential = create(:webauthn_credential, user: user, created_at: 1.hour.ago)

      get :index

      expect(response).to have_http_status(:success)
      expect(assigns(:credentials)).to eq([older_credential, newer_credential])
    end
  end

  describe 'GET #new' do
    let(:mock_options) do
      double(
        challenge: 'mock_challenge_123',
        user: { id: 'user123', name: 'test@example.com', display_name: 'testuser' },
        exclude: []
      )
    end

    before do
      allow(WebAuthn::Credential).to receive(:options_for_create).and_return(mock_options)
      allow(user).to receive(:webauthn_user_id).and_return('user123')
      allow(user).to receive(:email).and_return('test@example.com')
      allow(user).to receive(:username).and_return('testuser')
    end

    it 'generates WebAuthn creation options' do
      get :new

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
      expect(session[:webauthn_creation_challenge]).to eq('mock_challenge_123')
    end

    it 'excludes existing credentials' do
      existing_credential = create(:webauthn_credential, user: user, webauthn_id: 'existing_123')

      expect(WebAuthn::Credential).to receive(:options_for_create).with(
        user: {
          id: user.webauthn_user_id,
          name: user.email,
          display_name: user.username
        },
        exclude: ['existing_123']
      ).and_return(mock_options)

      get :new
    end
  end

  describe 'POST #create' do
    let(:mock_webauthn_credential) do
      double(
        id: 'credential_123',
        public_key: 'mock_public_key',
        sign_count: 0
      )
    end

    let(:credential_params) do
      {
        id: 'credential_123',
        rawId: 'base64_raw_id',
        type: 'public-key',
        response: {
          clientDataJSON: 'base64_client_data',
          attestationObject: 'base64_attestation'
        }
      }
    end

    before do
      session[:webauthn_creation_challenge] = 'test_challenge'
      allow(WebAuthn::Credential).to receive(:from_create).and_return(mock_webauthn_credential)
      allow(mock_webauthn_credential).to receive(:verify).and_return(true)
    end

    context 'with valid parameters' do
      it 'creates a new credential and enables 2FA' do
        expect(user).to receive(:enable_two_factor!)

        post :create, params: credential_params

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to include('registered successfully')
        expect(session[:webauthn_creation_challenge]).to be_nil
      end

      it 'creates credential with custom nickname' do
        params_with_nickname = credential_params.merge(nickname: 'My MacBook')

        post :create, params: params_with_nickname

        credential = user.webauthn_credentials.last
        expect(credential.nickname).to eq('My MacBook')
      end

      it 'creates credential with default nickname when none provided' do
        post :create, params: credential_params

        credential = user.webauthn_credentials.last
        expect(credential.nickname).to match(/Security Key \d+/)
      end

      it 'does not enable 2FA if already enabled' do
        allow(user).to receive(:two_factor_enabled?).and_return(true)
        expect(user).not_to receive(:enable_two_factor!)

        post :create, params: credential_params
      end
    end

    context 'with invalid parameters' do
      it 'returns error when credential save fails' do
        allow_any_instance_of(WebauthnCredential).to receive(:save).and_return(false)
        allow_any_instance_of(WebauthnCredential).to receive(:errors).and_return(
          double(full_messages: ['Validation failed'])
        )

        post :create, params: credential_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to save credential')
      end

      it 'returns error when WebAuthn verification fails' do
        allow(mock_webauthn_credential).to receive(:verify).and_raise(
          WebAuthn::Error.new('Invalid signature')
        )

        post :create, params: credential_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to include('WebAuthn verification failed')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user has multiple credentials' do
      it 'destroys the credential without disabling 2FA' do
        credential1 = create(:webauthn_credential, user: user)
        credential2 = create(:webauthn_credential, user: user)

        expect(user).not_to receive(:disable_two_factor!)

        delete :destroy, params: { id: credential1.id }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq('Security key removed successfully.')
        expect { credential1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(credential2.reload).to be_present
      end
    end

    context 'when user has only one credential' do
      it 'destroys the credential and disables 2FA' do
        credential = create(:webauthn_credential, user: user)

        expect(user).to receive(:disable_two_factor!)

        delete :destroy, params: { id: credential.id }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq('Security key removed successfully.')
        expect { credential.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it 'only allows user to delete their own credentials' do
      other_user = create(:user)
      other_credential = create(:webauthn_credential, user: other_user)

      expect {
        delete :destroy, params: { id: other_credential.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #auth_options' do
    let(:mock_options) do
      double(
        challenge: 'auth_challenge_123',
        allow_credentials: []
      )
    end

    before do
      allow(WebAuthn::Credential).to receive(:options_for_get).and_return(mock_options)
    end

    it 'generates WebAuthn authentication options' do
      credential = create(:webauthn_credential, user: user, webauthn_id: 'cred_123')

      expect(WebAuthn::Credential).to receive(:options_for_get).with(
        allow: ['cred_123']
      ).and_return(mock_options)

      get :auth_options

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
      expect(session[:webauthn_authentication_challenge]).to eq('auth_challenge_123')
    end
  end

  describe 'POST #verify' do
    let(:mock_webauthn_credential) do
      double(
        id: 'credential_123',
        sign_count: 1
      )
    end

    let(:stored_credential) { create(:webauthn_credential, user: user, webauthn_id: 'credential_123') }

    let(:verify_params) do
      {
        id: 'credential_123',
        rawId: 'base64_raw_id',
        type: 'public-key',
        response: {
          clientDataJSON: 'base64_client_data',
          authenticatorData: 'base64_authenticator_data',
          signature: 'base64_signature',
          userHandle: 'base64_user_handle'
        }
      }
    end

    before do
      session[:webauthn_authentication_challenge] = 'auth_challenge'
      stored_credential # Create the credential
      allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
    end

    context 'with valid authentication' do
      before do
        allow(mock_webauthn_credential).to receive(:verify).and_return(true)
      end

      it 'verifies successfully and marks session as 2FA verified' do
        post :verify, params: verify_params

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Authentication successful!')

        expect(session[:two_factor_verified]).to be true
        expect(session[:two_factor_verified_at]).to be_present
        expect(session[:webauthn_authentication_challenge]).to be_nil
      end

      it 'updates the credential sign count' do
        expect {
          post :verify, params: verify_params
        }.to change { stored_credential.reload.sign_count }.from(0).to(1)
      end
    end

    context 'with invalid authentication' do
      it 'returns error when credential not found' do
        # Create a mock that returns a nonexistent credential ID
        nonexistent_mock = double(id: 'nonexistent_credential')
        allow(WebAuthn::Credential).to receive(:from_get).and_return(nonexistent_mock)
        
        post :verify, params: verify_params.merge(id: 'nonexistent_credential')

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Credential not found')
      end

      it 'returns error when WebAuthn verification fails' do
        allow(mock_webauthn_credential).to receive(:verify).and_raise(
          WebAuthn::Error.new('Invalid signature')
        )

        post :verify, params: verify_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to include('Authentication failed')
      end
    end
  end

  describe 'authentication requirement' do
    it 'requires user to be authenticated' do
      allow(controller).to receive(:require_authentication).and_call_original
      allow(controller).to receive(:current_user).and_return(nil)

      get :index

      expect(controller).to have_received(:require_authentication)
    end
  end
end