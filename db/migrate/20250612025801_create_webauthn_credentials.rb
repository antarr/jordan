class CreateWebauthnCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :webauthn_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :webauthn_id, null: false
      t.text :public_key, null: false
      t.string :nickname, null: false
      t.integer :sign_count, null: false, default: 0

      t.timestamps
    end
    
    add_index :webauthn_credentials, :webauthn_id, unique: true
    add_index :webauthn_credentials, [:user_id, :nickname], unique: true
  end
end
