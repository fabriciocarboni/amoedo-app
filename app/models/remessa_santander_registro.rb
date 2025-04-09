# app/models/remessa_registro.rb
class RemessaSantanderRegistro < ApplicationRecord
  belongs_to :remessa_santander_header
  has_many :customers

  # Presence and length validations
  validates :codigo_do_registro, presence: true, length: { is: 1 }
  validates :tipo_de_inscricao_do_beneficiario, presence: true, length: { is: 2 }
  validates :numero_de_inscricao_do_beneficiario, presence: true, length: { is: 14 }
  validates :codigo_da_agencia_beneficiario, presence: true, length: { is: 4 }
  validates :conta_movimento_beneficiario, presence: true, length: { is: 8 }
  validates :conta_cobranca_beneficiario, presence: true, length: { is: 8 }
  validates :identificacao_do_boleto_na_empresa, presence: true, length: { maximum: 25 }
  validates :identificacao_do_boleto_no_banco, presence: true, length: { is: 8 }
  validates :data_do_desconto_2, length: { is: 6 }, allow_blank: true # Make it optional
  validates :reservado_uso_banco_1, length: { is: 1 }, allow_blank: true # Make it optional
  validates :codigo_de_multa, length: { is: 1 }, allow_blank: true # Make it optional
  validates :codigo_da_moeda, length: { is: 2 }, allow_blank: true # Make it optional
  validates :reservado_uso_banco_2, length: { is: 4 }, allow_blank: true # Make it optional
  validates :data_da_multa, length: { is: 6 }, allow_blank: true # Make it optional
  validates :tipo_de_cobranca, length: { is: 1 }, allow_blank: true # Make it optional
  validates :codigo_de_movimento_remessa, presence: true, length: { is: 2 }
  validates :numero_do_documento, presence: true, length: { maximum: 10 }
  validates :data_de_vencimento_do_boleto, presence: true, length: { is: 6 }
  validates :numero_do_banco_cobrador, length: { is: 3 }, allow_blank: true # Make it optional
  validates :codigo_agencia_cobradora, length: { is: 5 }, allow_blank: true # Make it optional
  validates :especie_do_boleto, length: { is: 2 }, allow_blank: true # Make it optional
  validates :identificacao_boleto_aceite_nao_aceite, length: { is: 1 }, allow_blank: true # Make it optional
  validates :data_de_emissao_do_boleto, presence: true, length: { is: 6 }
  validates :primeira_instrucao, length: { is: 2 }, allow_blank: true # Make it optional
  validates :segunda_instrucao, length: { is: 2 }, allow_blank: true # Make it optional
  validates :data_limite_para_concessao_do_desconto, length: { is: 6 }, allow_blank: true # Make it optional
  validates :tipo_de_inscricao_do_pagador, presence: true, length: { is: 2 }
  validates :numero_de_inscricao_do_pagador, presence: true, length: { is: 14 }
  validates :nome_do_pagador, presence: true, length: { maximum: 40 }
  validates :endereco_do_pagador, presence: true, length: { maximum: 40 }
  validates :bairro_do_pagador, length: { maximum: 12 }, allow_blank: true # Make it optional
  validates :cep_do_pagador, presence: true, length: { is: 5 }
  validates :sufixo_do_cep_do_pagador, length: { is: 3 }, allow_blank: true # Make it optional
  validates :cidade_do_pagador, presence: true, length: { maximum: 15 }
  validates :unidade_de_federacao_do_pagador, presence: true, length: { is: 2 }
  validates :numero_de_dias_corridos_para_protesto, length: { is: 2 }, allow_blank: true # Make it optional
  validates :numero_sequencial_do_registro_no_arquivo, presence: true, length: { is: 6 }
  validates :reservado_uso_banco_3, length: { is: 30 }, allow_blank: true # Add validation for this field, and make it optional
  validates :reservado_uso_banco_4, length: { is: 1 }, allow_blank: true # Add validation for this field, and make it optional
  validates :identificador_do_complemento, length: { is: 2 }, allow_blank: true # Add validation for this field, and make it optional
  validates :complemento, length: { is: 2 }, allow_blank: true # Add validation for this field, and make it optional
  validates :reservado_uso_banco_5, length: { is: 6 }, allow_blank: true # Add validation for this field, and make it optional
  validates :reservado_uso_banco_6, length: { is: 1 }, allow_blank: true # Add validation for this field, and make it optional

  # Numericality validations for decimal fields
  validates :percentual_de_multa, numericality: { allow_blank: false }
  validates :valor_do_boleto_em_outra_unidade, numericality: { allow_blank: false }
  validates :valor_nominal_do_boleto, numericality: { allow_blank: false }
  validates :valor_de_mora_dia, numericality: { allow_blank: false }
  validates :data_limite_para_concessao_do_desconto, numericality: { allow_blank: false }
  validates :valor_do_desconto_a_ser_concedido, numericality: { allow_blank: false }
  validates :percentual_do_iof_a_ser_recolhido, numericality: { allow_blank: false }
  validates :valor_do_abatimento_ou_valor_do_segundo_desconto, numericality: { allow_blank: false }

  # Custom validation to ensure decimal fields are properly formatted
  validate :validate_decimal_fields

  private

  def validate_decimal_fields
    decimal_fields = {
      percentual_de_multa: 2,
      valor_do_boleto_em_outra_unidade: 2,
      valor_nominal_do_boleto: 2,
      valor_de_mora_dia: 2,
      valor_do_desconto_a_ser_concedido: 2,
      percentual_do_iof_a_ser_recolhido: 5,
      valor_do_abatimento_ou_valor_do_segundo_desconto: 2
    }

    decimal_fields.each do |field, precision|
      value = send(field)
      next if value.blank?

      unless value.is_a?(Numeric)
        errors.add(field, "must be a number")
        next
      end

      # Check the number of decimal places
      decimal_part = value.to_s.split(".")[1]
      if decimal_part && decimal_part.length > precision
        errors.add(field, "cannot have more than #{precision} decimal places")
      end
    end
  end

end
