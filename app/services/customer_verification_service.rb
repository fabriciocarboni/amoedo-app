# app/services/customer_verification_service.rb
class CustomerVerificationService
  def self.exists?(cpf_cnpj)
    Customer.exists?(cpf_cnpj: cpf_cnpj)
  end

  def self.needs_asaas_creation?(cpf_cnpj)
    customer = Customer.find_by(cpf_cnpj: cpf_cnpj)
    customer && customer.asaas_customer_id.nil?
  end
end
