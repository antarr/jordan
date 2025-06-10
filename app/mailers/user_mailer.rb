class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = email_verification_url(token: @user.email_verification_token)

    mail(
      to: @user.email,
      subject: I18n.t('user_mailer.email_verification.subject')
    )
  end

  def account_unlock(user)
    @user = user
    @unlock_url = unlock_account_token_url(token: @user.auto_unlock_token)

    mail(
      to: @user.email,
      subject: I18n.t('user_mailer.account_unlock.subject')
    )
  end

  def account_locked(user)
    @user = user
    @unlock_url = unlock_account_token_url(token: @user.auto_unlock_token)

    mail(
      to: @user.email,
      subject: I18n.t('user_mailer.account_locked.subject')
    )
  end
end
