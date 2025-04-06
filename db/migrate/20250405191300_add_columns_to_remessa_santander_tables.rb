class AddColumnsToRemessaSantanderTables < ActiveRecord::Migration[8.0]
  def change
    add_column :remessa_santander_registros, :nome_arquivo_remessa, :string, null: false
    add_column :remessa_santander_registros, :processamento_id, :integer, null: false

    add_column :remessa_santander_headers, :nome_arquivo_remessa, :string, null: false
    add_column :remessa_santander_headers, :processamento_id, :integer, null: false

    add_index :remessa_santander_registros, :processamento_id
    add_index :remessa_santander_headers, :processamento_id
  end
end
