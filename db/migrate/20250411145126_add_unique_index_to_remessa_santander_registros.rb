class AddUniqueIndexToRemessaSantanderRegistros < ActiveRecord::Migration[8.0]
  def change
      add_index :remessa_santander_registros, :identificacao_do_boleto_na_empresa, unique: true, name: 'idx_remessa_santander_id_boleto_unique'
  end
end
