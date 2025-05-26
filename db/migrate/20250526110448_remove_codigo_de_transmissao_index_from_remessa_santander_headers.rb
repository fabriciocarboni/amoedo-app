class RemoveCodigoDeTransmissaoIndexFromRemessaSantanderHeaders < ActiveRecord::Migration[8.0]
  def change
    remove_index :remessa_santander_headers, name: "idx_remessa_headers_codigo_transmissao"
  end
end
