class AddMultiStepFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :username, :string
    add_column :users, :bio, :text
    add_column :users, :registration_step, :integer, default: 1
    add_column :users, :contact_method, :string
    add_column :users, :profile_photo, :string
    
    add_index :users, :username, unique: true
    add_index :users, :phone, unique: true
  end
end
