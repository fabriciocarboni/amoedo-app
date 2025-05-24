class ChangeContaMovimentoBeneficiarioToInteger < ActiveRecord::Migration[7.0]
  def up
    # Remove existing index if any
    remove_index :remessa_santander_registros, :conta_movimento_beneficiario, if_exists: true

    # Change column type from string to integer
    change_column :remessa_santander_registros, :conta_movimento_beneficiario, 'integer USING CAST(conta_movimento_beneficiario AS integer)'

    # Add non-unique index with a shorter name
    add_index :remessa_santander_registros, :conta_movimento_beneficiario, name: 'idx_remessa_santander_conta_movimento'
  end

  def down
    # Remove index using the shorter name
    remove_index :remessa_santander_registros, name: 'idx_remessa_santander_conta_movimento'

    # Change column type back to string
    change_column :remessa_santander_registros, :conta_movimento_beneficiario, :string, limit: 8
  end
end
