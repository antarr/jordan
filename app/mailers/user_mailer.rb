class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = email_verification_url(token: @user.email_verification_token)
    
    mail(
      to: @user.email,
      subject: "Please verify your email address"
    )
  end
end