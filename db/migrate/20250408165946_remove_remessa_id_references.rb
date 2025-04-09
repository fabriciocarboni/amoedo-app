class RemoveRemessaIdReferences < ActiveRecord::Migration[8.0]
  def up
    # Remove foreign key constraints first
    remove_foreign_key :cobrancas, column: :remessa_id
    remove_foreign_key :customers, column: :remessa_id

    # Remove indexes
    remove_index :cobrancas, :remessa_id
    remove_index :customers, :remessa_id

    # Remove columns
    remove_column :cobrancas, :remessa_id
    remove_column :customers, :remessa_id
  end

  def down
    # Add columns back
    add_column :cobrancas, :remessa_id, :bigint, null: false
    add_column :customers, :remessa_id, :bigint

    # Add indexes back
    add_index :cobrancas, :remessa_id
    add_index :customers, :remessa_id

    # Add foreign keys back
    add_foreign_key :cobrancas, :remessa_santander_registros, column: :remessa_id
    add_foreign_key :customers, :remessa_santander_registros, column: :remessa_id
  end
end
