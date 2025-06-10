class AddFailedLoginTrackingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :failed_login_attempts, :integer, default: 0, null: false
    add_column :users, :last_failed_login_at, :datetime
    add_column :users, :locked_by_admin, :boolean, default: false, null: false
    add_column :users, :auto_unlock_token, :string
    
    add_index :users, :auto_unlock_token, unique: true
    add_index :users, :failed_login_attempts
  end
end
