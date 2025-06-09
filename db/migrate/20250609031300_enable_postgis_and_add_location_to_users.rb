class EnablePostgisAndAddLocationToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add location fields to users table
    add_column :users, :latitude, :decimal, precision: 10, scale: 6
    add_column :users, :longitude, :decimal, precision: 10, scale: 6
    add_column :users, :location_name, :string
    add_column :users, :location_private, :boolean, default: false, null: false

    # Add spatial index for performance
    add_index :users, %i[latitude longitude]
  end
end
