class AddLockedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :locked_at, :datetime
  end
end
