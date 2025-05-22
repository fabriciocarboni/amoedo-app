class CreateShortUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :short_urls do |t|
      t.string :token
      t.string :blob_id
      t.string :filename
      t.datetime :expires_at

      t.timestamps
    end
    add_index :short_urls, :token, unique: true
    add_index :short_urls, :blob_id
  end
end
