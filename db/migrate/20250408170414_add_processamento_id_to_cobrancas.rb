class AddProcessamentoIdToCobrancas < ActiveRecord::Migration[8.0]
  def change
    add_column :cobrancas, :processamento_id, :integer, null: false
    add_index :cobrancas, :processamento_id
  end
end
