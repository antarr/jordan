class ProfilesController < ApplicationController
  before_action :require_authentication

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: t('profiles.update.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def change_password
    @user = current_user

    unless valid_current_password?
      @user.errors.add(:current_password, 'is incorrect')
      render :edit, status: :unprocessable_entity
      return
    end

    if update_user_password
      redirect_to edit_profile_path, notice: t('profiles.change_password.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def remove_photo
    @user = current_user

    if @user.profile_photo.attached?
      @user.profile_photo.purge
      redirect_to edit_profile_path, notice: t('profiles.remove_photo.success')
    else
      redirect_to edit_profile_path, alert: t('profiles.remove_photo.no_photo')
    end
  end

  private

  def profile_params
    # Password updates are not allowed through profile updates for security
    params.require(:user).permit(
      :email, :username, :bio, :location_name,
      :latitude, :longitude, :location_private,
      :profile_photo
    )
  end

  def password_change_params
    params.require(:password_change).permit(
      :current_password, :new_password, :new_password_confirmation
    )
  end

  def valid_current_password?
    @user.authenticate(password_change_params[:current_password])
  end

  def update_user_password
    @user.update(
      password: password_change_params[:new_password],
      password_confirmation: password_change_params[:new_password_confirmation]
    )
  end
end
