class ChangeIdentificacaoDoBoletoNoBancoToInteger < ActiveRecord::Migration[8.0]
  def up
    # Remove existing index if any
    remove_index :remessa_santander_registros, :identificacao_do_boleto_no_banco, if_exists: true

    # Change column type from string to integer
    change_column :remessa_santander_registros, :identificacao_do_boleto_no_banco, 'integer USING CAST(identificacao_do_boleto_no_banco AS integer)'

    # Add unique index
    add_index :remessa_santander_registros, :identificacao_do_boleto_no_banco, unique: true
  end

  def down
    # Remove unique index
    remove_index :remessa_santander_registros, :identificacao_do_boleto_no_banco

    # Change column type back to string
    change_column :remessa_santander_registros, :identificacao_do_boleto_no_banco, :string, limit: 8
  end
end
