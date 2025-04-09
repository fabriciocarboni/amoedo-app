class Customer < ApplicationRecord
  belongs_to :remessa, class_name: "RemessaSantanderRegistro", optional: true

  validates :name, :cpf_cnpj, presence: true
  validates :cpf_cnpj, uniqueness: true
  validates :asaas_customer_id, uniqueness: true, allow_nil: true

  has_many :cobrancas

  # Find all payments for this customer
  def find_payments_by_asaas_customer_id
    Cobranca.where(asaas_customer_id: self.asaas_customer_id)
  end

  # You might want to add this method if customers have an asaas_customer_id field
  def asaas_payments
    cobrancas.where(asaas_customer_id: self.asaas_customer_id)
  end
end
