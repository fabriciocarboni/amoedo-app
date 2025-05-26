class AddUniqueIndexToNomeArquivoRemessa < ActiveRecord::Migration[8.0]
  def change
     add_index :remessa_santander_headers, :nome_arquivo_remessa, unique: true, name: "idx_remessa_headers_nome_arquivo_remessa"
  end
end
