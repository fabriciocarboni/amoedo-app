# app/services/customer_handling_service.rb
class CustomerHandlingService
  def self.handle_customers(customers_data)
    local_customers = find_or_create_local_customers(customers_data)
    handle_asaas_customers(local_customers)

  rescue StandardError => e
    Rails.logger.error "[#{File.basename(__FILE__)}] Error in handling customers: #{e.message}"
  end


  private

  def self.find_or_create_local_customers(customer_data)
    cpf_cnpj = customer_data["numero_de_inscricao_do_beneficiario"]
    name = customer_data["nome_do_pagador"]

    Rails.logger.info("[#{File.basename(__FILE__)}] Attempting to find or create customer: CPF/CNPJ: #{cpf_cnpj}, Name: #{name}")

    customer = Customer.find_by(cpf_cnpj: cpf_cnpj)

    if customer
      Rails.logger.info("[#{File.basename(__FILE__)}] Existing customer found: ID: #{customer.id}, CPF/CNPJ: #{customer.cpf_cnpj}, Name: #{customer.name}")
      customer
    else
      Rails.logger.info("[#{File.basename(__FILE__)}] Customer not found. Creating new customer.")
      customer = Customer.create(cpf_cnpj: cpf_cnpj, name: name)
      if customer.persisted?
        Rails.logger.info("[#{File.basename(__FILE__)}] New customer created: ID: #{customer.id}, CPF/CNPJ: #{customer.cpf_cnpj}, Name: #{customer.name}")
      else
        Rails.logger.error("[#{File.basename(__FILE__)}] Failed to create customer: #{customer.errors.full_messages.join(', ')}")
      end
      customer
    end
  end


  # customers_data.map do |data|
  #   cpf_cnpj = data[:cpf_cnpj]
  #   name = data[:name]

  #   customer = Customer.find_or_create_by!(cpf_cnpj: cpf_cnpj, name: name)

  #   Rails.logger.info "[#{File.basename(__FILE__)}] Customer processed: #{customer.name}, CPF/CNPJ: #{customer.cpf_cnpj}"
  #   customer
  # end.compact
  # end


  def self.handle_asaas_customers(customers)
    customers_without_asaas_id = customers.select { |c| c.asaas_customer_id.blank? }
    return if customers_without_asaas_id.empty?

    cpf_cnpjs = customers_without_asaas_id.map(&:cpf_cnpj)
    existing_asaas_ids = AsaasCustomerVerificationService.batch_get_asaas_ids(cpf_cnpjs)

    customers_without_asaas_id.each do |customer|
      if existing_asaas_ids[customer.cpf_cnpj]
        customer.update(asaas_customer_id: existing_asaas_ids[customer.cpf_cnpj])
        Rails.logger.info "[#{File.basename(__FILE__)}] Updated customer with Asaas ID: #{customer.asaas_customer_id}"
      else
        create_asaas_customer(customer)
      end
    end
  end

  def self.create_asaas_customer(customer)
    result = AsaasCustomerCreationService.create(customer)
    if result[:success]
      customer.update(asaas_customer_id: result[:asaas_customer_id])
      Rails.logger.info "Created Asaas customer with ID: #{customer.asaas_customer_id}"
    else
      Rails.logger.error "[#{File.basename(__FILE__)}] Failed to create Asaas customer: #{result[:error]}"
    end
  end
end
