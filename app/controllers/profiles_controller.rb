# frozen_string_literal: true

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

  private

  def profile_params
    # Password updates are not allowed through profile updates for security
    params.require(:user).permit(
      :email, :username, :bio, :location_name,
      :latitude, :longitude, :location_private,
      :profile_photo
    )
  end
end
