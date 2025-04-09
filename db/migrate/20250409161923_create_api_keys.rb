class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.string :access_token, null: false
      t.string :client_name, null: false
      t.string :email, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :api_keys, :access_token, unique: true
    add_index :api_keys, :email, unique: true
  end
end
