class Customer < ApplicationRecord
  validates :name, :cpf_cnpj, presence: true
  validates :cpf_cnpj, uniqueness: true
  validates :asaas_customer_id, uniqueness: true, allow_nil: true
end
