class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = email_verification_url(token: @user.email_verification_token)

    mail(
      to: @user.email,
      subject: I18n.t('user_mailer.email_verification.subject')
    )
  end
end
