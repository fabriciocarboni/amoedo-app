class CreateRemessaSantanderHeaders < ActiveRecord::Migration[8.0]
  def change
    create_table :remessa_santander_headers do |t|
      t.string :codigo_do_registro, limit: 1
      t.string :codigo_da_remessa, limit: 1
      t.string :literal_de_transmissao, limit: 7
      t.string :codigo_do_tipo_servico, limit: 2
      t.string :literal_de_servico, limit: 15
      t.string :codigo_de_transmissao, limit: 20
      t.string :nome_do_beneficiario, limit: 30
      t.string :codigo_do_banco, limit: 3
      t.string :nome_do_banco, limit: 15
      t.string :data_da_geracao_do_arquivo, limit: 6
      t.string :reservado_uso_banco_1, limit: 6
      t.string :mensagem_1, limit: 47
      t.string :mensagem_2, limit: 47
      t.string :mensagem_3, limit: 47
      t.string :mensagem_4, limit: 47
      t.string :mensagem_5, limit: 47
      t.string :reservado_uso_banco_2, limit: 34
      t.string :reservado_uso_banco_3, limit: 6
      t.string :numero_sequencial_do_arquivo, limit: 3
      t.string :numero_sequencial_do_registro_no_arquivo, limit: 6

      t.timestamps
    end
  end
end
