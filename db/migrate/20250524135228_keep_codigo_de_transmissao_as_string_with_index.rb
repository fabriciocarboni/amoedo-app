class KeepCodigoDeTransmissaoAsStringWithIndex < ActiveRecord::Migration[8.0]
  def up
    # Remove existing index if any
    remove_index :remessa_santander_headers, :codigo_de_transmissao, if_exists: true

    # Ensure the column is a string with sufficient length
    change_column :remessa_santander_headers, :codigo_de_transmissao, :string, limit: 20

    # Add unique index with a shorter name
    add_index :remessa_santander_headers, :codigo_de_transmissao,
              name: 'idx_remessa_headers_codigo_transmissao',
              unique: true
  end

  def down
    # Remove unique index
    remove_index :remessa_santander_headers, name: 'idx_remessa_headers_codigo_transmissao'
  end
end
