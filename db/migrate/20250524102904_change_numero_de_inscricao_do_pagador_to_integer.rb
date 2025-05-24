class ChangeNumeroDeInscricaoDoPagadorToInteger < ActiveRecord::Migration[8.0]
  def up
    # Remove existing index if any
    remove_index :remessa_santander_registros, :numero_de_inscricao_do_pagador, if_exists: true

    # Change column type from string to bigint (since it's a 14-character number)
    change_column :remessa_santander_registros, :numero_de_inscricao_do_pagador, 'bigint USING CAST(numero_de_inscricao_do_pagador AS bigint)'

    # Add non-unique index
    add_index :remessa_santander_registros, :numero_de_inscricao_do_pagador
  end

  def down
    # Remove index
    remove_index :remessa_santander_registros, :numero_de_inscricao_do_pagador

    # Change column type back to string
    change_column :remessa_santander_registros, :numero_de_inscricao_do_pagador, :string, limit: 14
  end
end
