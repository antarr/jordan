class EmailVerificationJob < ApplicationJob
  queue_as :default

  def perform(user)
    UserMailer.email_verification(user).deliver_now
  end
end
