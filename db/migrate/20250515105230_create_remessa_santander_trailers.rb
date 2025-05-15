class CreateRemessaSantanderTrailers < ActiveRecord::Migration[8.0]
  def change
    create_table :remessa_santander_trailers do |t|
      t.string :codigo_do_registro, limit: 1
      t.string :quantidade_de_registros_no_arquivo, limit: 6
      t.decimal :valor_total_dos_boletos, precision: 11, scale: 2
      t.string :numero_sequencial_de_registros_no_arquivo, limit: 6
      t.string :nome_arquivo_remessa, limit: 255, null: false
      t.integer :processamento_id, null: false

      t.timestamps
    end
    add_index :remessa_santander_trailers, :processamento_id, unique: false
  end
end
