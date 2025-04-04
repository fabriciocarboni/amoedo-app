# app/services/santander/remessa_registro_processor_service.rb
module Santander
  class RemessaRegistroProcessorService
    class ParseError < StandardError; end

    def initialize(registro_line, header_data)
      @registro_line = registro_line
      @header_data = header_data
      @schema = load_schema
    end

    def parse
      data = @schema.each_with_object({}) do |(field, details), parsed_data|
        parsed_data[field] = extract_and_process_field(field, details)
        # Rails.logger.debug "Processing field: #{field}, value: #{parsed_data[field]}"
      end
      # Rails.logger.debug "Parsed data: #{data.inspect}"

      Rails.logger.info "Numero de inscricao do beneficiario: #{data['numero_de_inscricao_do_pagador']}"
      Rails.logger.info "Nome do pagador: #{data['nome_do_pagador']}"

      check_and_create_customer(data["numero_de_inscricao_do_pagador"], data["nome_do_pagador"])

      data
    rescue ParseError => e
      Rails.logger.error "Parse error for registro: #{e.message}"
      raise
    rescue StandardError => e
      Rails.logger.error "Unexpected error processing registro: #{e.message}"
      raise ParseError, "Failed to process registro: #{e.message}"
    end

    private

    def check_and_create_customer(cpf_cnpj, name)
      Rails.logger.info "Checking locally customer with CPF/CNPJ: #{cpf_cnpj}, Name: #{name}"
      customer = Customer.find_or_initialize_by(cpf_cnpj: cpf_cnpj)

      if customer.new_record?
        customer.name = name
        if customer.save
          Rails.logger.info "Created new customer: #{customer.name}"
        else
          Rails.logger.error "Failed to create customer: #{customer.errors.full_messages.join(', ')}"
          return
        end
      end

      handle_asaas_customer(customer)
    rescue StandardError => e
      Rails.logger.error "Error in check_and_create_customer: #{e.message}"
    end

    def handle_asaas_customer(customer)
      Rails.logger.info "Handling Asaas customer for local customer with CPF/CNPJ: #{customer.cpf_cnpj}"

      # First, check if the customer exists in Asaas by CPF/CNPJ
      existing_asaas_id = AsaasCustomerVerificationService.get_asaas_id(customer.cpf_cnpj)

      if existing_asaas_id
        Rails.logger.info "Found existing Asaas customer with ID: #{existing_asaas_id}"
        if existing_asaas_id != customer.asaas_customer_id
          Rails.logger.info "Updating local record with correct Asaas ID"
          customer.update(asaas_customer_id: existing_asaas_id)
        else
          Rails.logger.info "Local Asaas ID matches the one in Asaas, no action needed"
        end
      else
        Rails.logger.info "No Asaas customer found for CPF/CNPJ: #{customer.cpf_cnpj}, creating it"
        create_asaas_customer(customer)
      end
    end

    def create_asaas_customer(customer)
      result = AsaasCustomerCreationService.create(customer)
      if result[:success]
        new_asaas_id = result[:asaas_customer_id]
        Rails.logger.info "Successfully created Asaas customer with ID: #{new_asaas_id}"
        customer.update(asaas_customer_id: new_asaas_id)
      else
        Rails.logger.error "Failed to create Asaas customer: #{result[:error]}"
      end
    end

    def load_schema
      YAML.load_file(Rails.root.join("config", "remessa_schema.yml"))["registro_movimento"]
    end

    def extract_and_process_field(field, details)
      value = extract_field_value(field, details)
      process_field(value, details)
    end

    def extract_field_value(field, details)
      value = @registro_line[details["start"] - 1, details["length"]]
      if value.nil? || value.empty?
        raise ParseError, "Missing field #{field} at position #{details["start"]}"
      end
      value
    end

    def process_field(value, details)
      value = value.strip
      if details["decimal"]
        (value.to_i / (10.0 ** details["decimal"]))
      else
        value
      end
    rescue StandardError => e
      Rails.logger.error "Data conversion error for field: #{e.message}"
      raise ParseError, "Invalid data format for field: #{e.message}"
    end
  end
end
