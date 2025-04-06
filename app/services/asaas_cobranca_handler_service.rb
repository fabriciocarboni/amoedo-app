# app/services/asaas_customer_handler_service.rb
require "httparty"

class AsaasCobrancaHandlerService
  include HTTParty
  base_uri ENV["ASAAS_BASE_URI"]


  def self.handle_cobrancas(cobrancas)
    cobrancas.each do |cobranca|
      cpf_cnpj = cobranca["numero_de_inscricao_do_pagador"]
      name = cobranca["nome_do_pagador"]

      # Check if customer exists locally create it otherwise
      customer = Customer.find_or_create_by(cpf_cnpj: cpf_cnpj) do |c|
        c.name = name
        customer
      end

      if customer.asaas_customer_id.blank?
        # create asaas customer and get the id to create the cobranca
        Rails.logger.info("[#{File.basename(__FILE__)}] asaas_customer_id is null, checking in asaas for #{name}")
        asaas_customer = ::AsaasCustomerVerificationService.exists?(cpf_cnpj)

        if asaas_customer
          # update asaas_customer_id locallt
          Rails.logger.info("[#{File.basename(__FILE__)}] Updating locally asaas_customer_id for #{name}")
          customer.update(asaas_customer_id: asaas_customer["id"])
        end
        # else
        #   # if the customer exists locally, has asaas_customer_id need to check iif it exists in asaas
        #   Rails.logger.info("[#{File.basename(__FILE__)}] Customer exists locally, has asaas_customer_id but not exists in Asaas #{name}")
        #   asaas_customer_with_asaas_customer_id = ::AsaasCustomerVerificationService.exists?(cpf_cnpj)

        #   if asaas_customer_with_asaas_customer_id # if exists in asaas
        #     # update customer locally with the assas customer id
        #     Rails.logger.info("[#{File.basename(__FILE__)}] Updating asaas_customer_id for #{name}")
        #     customer.update(asaas_customer_id: asaas_customer_with_asaas_customer_id["id"])
        #   else
        #     # create it
        #     # if the user exists locally and not in asaas create it
        #     Rails.logger.info("[#{File.basename(__FILE__)}] Customer does not exist in Asaas, creating it for #{name}")
        #     new_customer_asaas = ::AsaasCustomerCreationService.create(cpf_cnpj, name)

        #     # update customer locally with the new assas customer id
        #     Rails.logger.info("[#{File.basename(__FILE__)}] Updating asaas_customer_id for #{name}")
        #     customer.update(asaas_customer_id: new_customer_asaas["id"])
        #   end

      else
        # client has already asaas_customer_id locally so let's create the cobrança
        cobranca = create_cobranca(cobranca)
        new_cobranca = ::AsaasCobrancaCreationService(cobranca)

        Rails.logger.info("new_cobranca: #{new_cobranca})


      end
    end
  end



  def self.create_cobranca(cobrancas)
    # define the fields to create cobranca
    # cpf_cnpj = cobranca["numero_de_inscricao_do_pagador"]


    # customer_exists_result = ::AsaasCustomerVerificationService.exists?(cpf_cnpj)
    # puts("customer_exists_result: #{customer_exists_result}")
  end
end
