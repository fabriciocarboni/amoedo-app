class CreateRemessaSantanderRegistros < ActiveRecord::Migration[8.0]
  def change
    create_table :remessa_santander_registros do |t|
      t.references :remessa_santander_header, foreign_key: true

      t.string :codigo_do_registro, limit: 1
      t.string :tipo_de_inscricao_do_beneficiario, limit: 2
      t.string :numero_de_inscricao_do_beneficiario, limit: 14
      t.string :codigo_da_agencia_beneficiario, limit: 4
      t.string :conta_movimento_beneficiario, limit: 8
      t.string :conta_cobranca_beneficiario, limit: 8
      t.string :identificacao_do_boleto_na_empresa, limit: 25
      t.string :identificacao_do_boleto_no_banco, limit: 8
      t.string :data_do_desconto_2, limit: 6
      t.string :reservado_uso_banco_1, limit: 1
      t.string :codigo_de_multa, limit: 1
      t.decimal :percentual_de_multa, precision: 4, scale: 2
      t.string :codigo_da_moeda, limit: 2
      t.decimal :valor_do_boleto_em_outra_unidade, precision: 10, scale: 2
      t.string :reservado_uso_banco_2, limit: 4
      t.string :data_da_multa, limit: 6
      t.string :tipo_de_cobranca, limit: 1
      t.string :codigo_de_movimento_remessa, limit: 2
      t.string :numero_do_documento, limit: 10
      t.string :data_de_vencimento_do_boleto, limit: 6
      t.decimal :valor_nominal_do_boleto, precision: 13, scale: 2
      t.string :numero_do_banco_cobrador, limit: 3
      t.string :codigo_agencia_cobradora, limit: 5
      t.string :especie_do_boleto, limit: 2
      t.string :identificacao_boleto_aceite_nao_aceite, limit: 1
      t.string :data_de_emissao_do_boleto, limit: 6
      t.string :primeira_instrucao, limit: 2
      t.string :segunda_instrucao, limit: 2
      t.decimal :valor_de_mora_dia, precision: 13, scale: 2
      t.string :data_limite_para_concessao_do_desconto, limit: 6
      t.decimal :valor_do_desconto_a_ser_concedido, precision: 13, scale: 2
      t.decimal :percentual_do_iof_a_ser_recolhido, precision: 13, scale: 5
      t.decimal :valor_do_abatimento_ou_valor_do_segundo_desconto, precision: 13, scale: 2
      t.string :tipo_de_inscricao_do_pagador, limit: 2
      t.string :numero_de_inscricao_do_pagador, limit: 14
      t.string :nome_do_pagador, limit: 40
      t.string :endereco_do_pagador, limit: 40
      t.string :bairro_do_pagador, limit: 12
      t.string :cep_do_pagador, limit: 5
      t.string :sufixo_do_cep_do_pagador, limit: 3
      t.string :cidade_do_pagador, limit: 15
      t.string :unidade_de_federacao_do_pagador, limit: 2
      t.string :reservado_uso_banco_3, limit: 30
      t.string :reservado_uso_banco_4, limit: 1
      t.string :identificador_do_complemento, limit: 2
      t.string :complemento, limit: 2
      t.string :reservado_uso_banco_5, limit: 6
      t.string :numero_de_dias_corridos_para_protesto, limit: 2
      t.string :reservado_uso_banco_6, limit: 1
      t.string :numero_sequencial_do_registro_no_arquivo, limit: 6

      t.timestamps
    end
  end
end
