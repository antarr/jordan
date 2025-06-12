class AddTwoFactorToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :two_factor_enabled, :boolean, default: false, null: false
    add_index :users, :two_factor_enabled
  end
end
