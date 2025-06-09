class RegistrationsController < ApplicationController
  include Wicked::Wizard
  include ApplicationHelper

  steps :contact_details, :username, :bio, :profile_photo

  before_action :find_or_create_user, only: %i[show update]
  before_action :check_phone_registration_enabled, only: %i[create show update]

  def new
    @user = User.new
  end

  def create
    unless params[:contact_method].present?
      @user = User.new
      flash.now[:alert] = I18n.t('controllers.registrations.create.contact_method_required')
      render :new, status: :unprocessable_entity
      return
    end

    @user = User.new(contact_method: params[:contact_method])
    @user.registration_step = 1

    # Bypassing validations here is intentional because this is the first step
    # in a multi-step registration process. Validations will be applied in
    # subsequent steps as the user completes the registration flow.
    if @user.save(validate: false)
      session[:registration_user_id] = @user.id
      redirect_to registration_step_path(:contact_details)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user = current_user_registration
    @step_number = step_number
    @total_steps = steps.count
    render_wizard
  end

  def update
    @user = current_user_registration

    case step
    when :contact_details
      @user.assign_attributes(contact_details_params)
      @user.registration_step = 2
      if @user.save
        if @user.contact_method == 'email' && @user.email_verification_token.blank?
          @user.generate_email_verification_token!
        end
        redirect_to next_wizard_path
      else
        render_wizard
      end
    when :username
      @user.assign_attributes(username_params)
      @user.registration_step = 3
      if @user.save
        redirect_to next_wizard_path
      else
        render_wizard
      end
    when :bio
      @user.assign_attributes(bio_params)
      @user.registration_step = 4
      if @user.save
        redirect_to next_wizard_path
      else
        render_wizard
      end
    when :profile_photo
      @user.assign_attributes(profile_photo_params)
      @user.registration_step = 5
      if @user.save
        complete_registration
      else
        render_wizard
      end
    end
  end

  private

  def current_user_registration
    @current_user_registration ||= User.find_by(id: session[:registration_user_id])
  end

  def find_or_create_user
    redirect_to new_registration_path unless current_user_registration
  end

  def complete_registration
    if @user.contact_method == 'email'
      EmailVerificationJob.perform_later(@user)
      session[:registration_user_id] = nil
      redirect_to new_session_path, notice: I18n.t('controllers.registrations.complete_registration.email_success')
    else
      session[:registration_user_id] = nil
      redirect_to new_session_path, notice: I18n.t('controllers.registrations.complete_registration.phone_success')
    end
  end

  def contact_details_params
    if current_user_registration.contact_method == 'email'
      params.require(:user).permit(:email, :password, :password_confirmation)
    else
      params.require(:user).permit(:phone, :password, :password_confirmation)
    end
  end

  def username_params
    params.require(:user).permit(:username)
  end

  def bio_params
    params.require(:user).permit(:bio)
  end

  def profile_photo_params
    params.require(:user).permit(:profile_photo)
  end

  def step_number
    case step
    when :contact_details then 2
    when :username then 3
    when :bio then 4
    when :profile_photo then 5
    else 1
    end
  end

  def step_name
    case step
    when :contact_details then 'Contact Details'
    when :username then 'Username'
    when :bio then 'Bio'
    when :profile_photo then 'Profile Photo'
    else 'Getting Started'
    end
  end

  def check_phone_registration_enabled
    if (params[:contact_method] == 'phone' || current_user_registration&.contact_method == 'phone') && 
       !feature_enabled?(:phone_registration_enabled)
      redirect_to new_registration_path, alert: I18n.t('controllers.registrations.phone_registration_disabled')
    end
  end

  helper_method :step_number, :step_name
end

