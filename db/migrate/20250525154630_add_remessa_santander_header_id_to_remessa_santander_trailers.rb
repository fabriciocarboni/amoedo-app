class AddRemessaSantanderHeaderIdToRemessaSantanderTrailers < ActiveRecord::Migration[8.0]
  def change
    add_column :remessa_santander_trailers, :remessa_santander_header_id, :bigint
    add_foreign_key :remessa_santander_trailers, :remessa_santander_headers
    add_index :remessa_santander_trailers, :remessa_santander_header_id, name: "idx_on_remessa_santander_header_id_4776"
  end
end
