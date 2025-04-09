class ChangeNomeBancoToStringInCobrancas < ActiveRecord::Migration[8.0]
  def change
    change_column :cobrancas, :nome_banco, :string
  end
end
