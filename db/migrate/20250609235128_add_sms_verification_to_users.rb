class AddSmsVerificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sms_verification_code, :string
    add_column :users, :sms_verification_code_expires_at, :datetime
    add_column :users, :phone_verified_at, :datetime

    add_index :users, :sms_verification_code, unique: true
  end
end
