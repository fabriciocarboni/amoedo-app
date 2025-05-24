class ChangeNumeroDeInscricaoDoBeneficiarioToInteger < ActiveRecord::Migration[8.0]
  def up
    # Remove existing index if any
    remove_index :remessa_santander_registros, :numero_de_inscricao_do_beneficiario, if_exists: true

    # Change column type from string to bigint (since it's a 14-character number)
    change_column :remessa_santander_registros, :numero_de_inscricao_do_beneficiario, 'bigint USING CAST(numero_de_inscricao_do_beneficiario AS bigint)'

    # Add non-unique index with a shorter name
    add_index :remessa_santander_registros, :numero_de_inscricao_do_beneficiario,
              name: 'idx_remessa_santander_num_inscricao_benef'
  end

  def down
    # Remove index using the shorter name
    remove_index :remessa_santander_registros, name: 'idx_remessa_santander_num_inscricao_benef'

    # Change column type back to string
    change_column :remessa_santander_registros, :numero_de_inscricao_do_beneficiario, :string, limit: 14
  end
end
