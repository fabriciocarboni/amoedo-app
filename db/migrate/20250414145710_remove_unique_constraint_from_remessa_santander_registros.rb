class RemoveUniqueConstraintFromRemessaSantanderRegistros < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing unique index
    remove_index :remessa_santander_registros, name: "idx_remessa_santander_id_boleto_unique"

    # Add a new non-unique index to maintain query performance
    add_index :remessa_santander_registros, :identificacao_do_boleto_na_empresa,
              name: "index_remessa_santander_registros_on_id_boleto"
  end

  def down
    # Remove the non-unique index
    remove_index :remessa_santander_registros, name: "index_remessa_santander_registros_on_id_boleto"

    # Re-add the unique index
    add_index :remessa_santander_registros, :identificacao_do_boleto_na_empresa,
              name: "idx_remessa_santander_id_boleto_unique", unique: true
  end
end
