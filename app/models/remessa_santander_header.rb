# app/models/remessa_header.rb
class RemessaSantanderHeader < ApplicationRecord
  has_many :remessa_santander_registros, dependent: :destroy

  before_validation :prepare_fields

  validates :codigo_do_registro, presence: true, length: { is: 1 }
  validates :codigo_da_remessa, presence: true, length: { is: 1 }
  validates :literal_de_transmissao, presence: true, length: { is: 7 }
  validates :codigo_do_tipo_servico, presence: true, length: { is: 2 }
  validates :literal_de_servico, presence: true, length: { is: 15 }, format: { with: /\A[A-Z0-9 ]{15}\z/ }
  validates :codigo_de_transmissao, presence: true, length: { is: 20 }
  validates :nome_do_beneficiario, presence: true, length: { maximum: 30 }
  validates :codigo_do_banco, presence: true, length: { is: 3 }
  validates :nome_do_banco, presence: true, length: { maximum: 15 }
  validates :data_da_geracao_do_arquivo, presence: true, length: { is: 6 }
  validates :numero_sequencial_do_arquivo, presence: true, length: { is: 3 }
  validates :numero_sequencial_do_registro_no_arquivo, presence: true, length: { is: 6 }

  private

  def prepare_fields
    self.literal_de_servico = literal_de_servico.to_s.upcase.ljust(15)[0...15] if literal_de_servico
    # Prepare other fields if necessary
  end
end
