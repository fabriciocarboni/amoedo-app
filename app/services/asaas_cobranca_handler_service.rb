# app/services/asaas_customer_handler_service.rb
require "httparty"

class AsaasCobrancaHandlerService
  include HTTParty
  base_uri ENV["ASAAS_BASE_URI"]


  def self.handle_cobrancas(cobrancas, processamento_id)
    cobrancas.each do |cobranca|
      cpf_cnpj = cobranca["numero_de_inscricao_do_pagador"].to_s.gsub(/^0+/, "") # remove left zeros
      name = cobranca["nome_do_pagador"]
      value = cobranca["valor_nominal_do_boleto"]
      billingType = "BOLETO"
      dueDate = Date.strptime(cobranca["data_de_vencimento_do_boleto"], "%d%m%y").strftime("%Y-%m-%d") # convert from DDMMYY to YYYY-MM-DD to pass to Asaas api
      dueDateTexto = (Date.strptime(cobranca["data_de_vencimento_do_boleto"], "%d%m%y") + 1).strftime("%d/%m/%Y") # text to be displayed in description as DD/MM/DD + 1 day
      externalReference = cobranca["identificacao_do_boleto_na_empresa"].to_s.gsub(/^0+/, "") # remove left zeros
      fine = (cobranca["percentual_de_multa"].to_f * 100).to_i.to_s # copnverting 0.02 to 2
      fine_texto = ((value.to_f * (fine.to_f / 100)).round(2)).to_s # calculate the fine in R$ to show in description
      interest = 3 # juros de mora 3%
      interest_mora_dia_texto = (((value.to_f * (interest.to_f / 100)) / 30).round(2)).to_s # Calculates mora diaria (valor * interest) / 30 dias
      description = "APOS VENCIMENTO MORA DIARIA DE R$#{interest_mora_dia_texto}\nMulta no valor de R$#{fine_texto} para pagamento a partir do dia #{dueDateTexto}.\nSUJEITO A PROTESTO 05 DIAS UTEIS APÓS VENCIMENTO"

      # Check if customer exists locally create it otherwise
      customer = Customer.find_or_create_by(cpf_cnpj: cpf_cnpj) do |c|
        c.name = name
      end

      if customer.nil? || customer.asaas_customer_id.blank? # This ensures it's only try to access asaas_customer_id if customer is not nil.
        puts("0000000000000")
        # create asaas customer and get the id to create the cobranca
        Rails.logger.info("[#{File.basename(__FILE__)}] asaas_customer_id is null, checking in asaas for #{name}")
        asaas_customer = ::AsaasCustomerVerificationService.exists?(cpf_cnpj)
        puts("asaas_customer: #{asaas_customer}")

        if !asaas_customer[:data]["data"].empty?
          # update asaas_customer_id locally
          Rails.logger.info("[#{File.basename(__FILE__)}] Updating locally asaas_customer_id for #{name}")
          # customer.update(asaas_customer_id: asaas_customer["id"])
          asaas_customer_id = asaas_customer[:data]["data"].first["id"]
          customer.update(asaas_customer_id: asaas_customer_id)

           cobranca_params = build_cobranca_hash(
              { asaas_customer_id: asaas_customer_id }, # pass as a hash
              name,
              cpf_cnpj,
              value,
              billingType,
              dueDate,
              externalReference,
              description,
              fine,
              interest
            )

            Rails.logger.info("[#{File.basename(__FILE__)}] Creating cobranca...cobranca_params: #{cobranca_params}")
            cobranca_result = ::AsaasCobrancaCreationService.create(cobranca_params)
            puts("cobranca_result: #{cobranca_result}")
            if cobranca_result[:success]
              puts("131313131")
              Rails.logger.info("[#{File.basename(__FILE__)}] Payment created successfully. #{cobranca_result[:data]}")

              # save the payment itself along with current customer data so i can have its id
              save_cobranca(cobranca_result[:data], customer, processamento_id)

            else
              Rails.logger.info("[#{File.basename(__FILE__)}] Failed to create payment: #{name}")
            end



        else
          puts("12121212121")
        # Create the customer
        Rails.logger.info("[#{File.basename(__FILE__)}] Customer does not exist in Asaas, creating it for #{name}")
        new_customer_asaas = ::AsaasCustomerCreationService.create(cpf_cnpj, name)
        Rails.logger.info("[#{File.basename(__FILE__)}] new_customer_asaas: #{new_customer_asaas}")

          if new_customer_asaas

            # updating current customer with recently created asaas_customer_id
            Rails.logger.info("[#{File.basename(__FILE__)}] updating current customer with recently created asaas_customer_id for #{name}, #{new_customer_asaas[:asaas_customer_id]}")
            customer.update(asaas_customer_id: new_customer_asaas[:asaas_customer_id])

            # Building the cobranca hash to pass it through
            cobranca_params = build_cobranca_hash(
              new_customer_asaas,
              name,
              cpf_cnpj,
              value,
              billingType,
              dueDate,
              externalReference,
              description,
              fine,
              interest
            )

            Rails.logger.info("[#{File.basename(__FILE__)}] Creating cobranca...cobranca_params: #{cobranca_params}")
            cobranca_result = ::AsaasCobrancaCreationService.create(cobranca_params)

            if cobranca_result[:success]
              Rails.logger.info("[#{File.basename(__FILE__)}] Payment created successfully. #{cobranca_result[:data]}")

              # save the payment itself along with current customer data so i can have its id
              save_cobranca(cobranca_result[:data], customer, processamento_id)

            else
              Rails.logger.info("[#{File.basename(__FILE__)}] Failed to create payment: #{name}")
            end
            # Rails.logger.info("new_cobranca: #{new_cobranca}")
          else
            Rails.logger.info("[#{File.basename(__FILE__)}] Failed creating customer in Asaas: #{cobranca_result[:data]}")
          end
        end
      else
        puts("2222222222222")
        # local customer has asaas_customer_id. Checking if the customer exists in asaas
        asaas_customer_with_asaas_customer_id = ::AsaasCustomerVerificationService.exists?(cpf_cnpj)

        puts("cpf_cnpj: #{cpf_cnpj}")
        puts("asaas_customer_with_asaas_customer_id: #{asaas_customer_with_asaas_customer_id}")

        # if !asaas_customer_with_asaas_customer_id
        if asaas_customer_with_asaas_customer_id[:data]["data"].empty?
          puts("33333333333333")
          # create the customer and update assas_customer_id
          Rails.logger.info("[#{File.basename(__FILE__)}] Customer does not exist in Asaas, creating it for #{name}")
          new_customer_asaas = ::AsaasCustomerCreationService.create(cpf_cnpj, name)

          # update customer locally with the new assas customer id
          Rails.logger.info("[#{File.basename(__FILE__)}] Updating asaas_customer_id #{new_customer_asaas["id"]} for #{name}")
          customer.update(asaas_customer_id: new_customer_asaas["id"])
        else
          puts("444444444")
          puts("asaas_customer_with_asaas_customer_id: #{asaas_customer_with_asaas_customer_id}")
          Rails.logger.info("[#{File.basename(__FILE__)}] Updating existing customer with asaas_customer_id for #{name}")
          customer.update(asaas_customer_id: asaas_customer_with_asaas_customer_id[:data]["data"].first["id"])
        end


        # customer already exists locallay with asaas_customer_id
        # let's create a cobranca for him

        # Getting asaas_customer_id for current existent customer
        get_asaas_customer = Customer.find_by(cpf_cnpj: cpf_cnpj)
        puts("55555555555")
        # check if asaas_customer_id is null
        # if get_asaas_customer.nil?
        #   puts("6666666666666")
        #   puts("Customer with CPF/CNPJ #{cpf_cnpj} not found.")
        # end

        asaas_customer_id = get_asaas_customer.asaas_customer_id
        Rails.logger.info("[#{File.basename(__FILE__)}] customer already exists locally with asaas_customer_id #{asaas_customer_id} for #{name}")

        cobranca_params = build_cobranca_hash(
          { asaas_customer_id: asaas_customer_id }, # Pass as a hash
          name,
          cpf_cnpj,
          value,
          billingType,
          dueDate,
          externalReference,
          description,
          fine,
          interest
        )
        Rails.logger.info("[#{File.basename(__FILE__)}] Creating cobranca...cobranca_params: #{cobranca_params}")

        # Building the cobranca hash to pass it through
        cobranca_result = ::AsaasCobrancaCreationService.create(cobranca_params)

        if cobranca_result[:success]
          Rails.logger.info("[#{File.basename(__FILE__)}] Cobranca created successfully. #{cobranca_result[:data]}")
          # save the payment itself along with current customer data so i can have its id
          save_cobranca(cobranca_result[:data], customer, processamento_id)
        else
          Rails.logger.info("[#{File.basename(__FILE__)}] Cobranca not created. #{cobranca_result[:data]}")
          { success: false, error: "Failed to create cobranca: #{cobranca_result[:data]}" }
        end
      end
    end
  end


  def self.build_cobranca_hash(new_customer_asaas, name, cpf_cnpj, value, billingType,
                      dueDate, externalReference, description, fine, interest)
    {
      asaas_customer_id: new_customer_asaas[:asaas_customer_id],
      nome: name,
      cpf_cnpj: cpf_cnpj,
      value: value,
      billingType: billingType,
      dueDate: dueDate,
      externalReference: externalReference,
      description: description,
      fine: { value: fine, type: "PERCENTAGE" },
      interest: interest
    }
  end

  def self.save_cobranca(payment_data, customer, processamento_id)
    cobranca = Cobranca.new(
      # Basic Payment Information
      asaas_payment_id: payment_data["id"],
      asaas_customer_id: payment_data["customer"],
      date_created: Date.parse(payment_data["dateCreated"]),
      status: payment_data["status"],

      # Financial Details
      value: payment_data["value"],
      net_value: payment_data["netValue"],
      original_value: payment_data["originalValue"],
      interest_value: payment_data["interestValue"],
      nome_banco: "SANTANDER",

      # Payment Schedule
      due_date: Date.parse(payment_data["dueDate"]),
      original_due_date: payment_data["originalDueDate"] ? Date.parse(payment_data["originalDueDate"]) : nil,
      payment_date: payment_data["paymentDate"] ? Date.parse(payment_data["paymentDate"]) : nil,
      client_payment_date: payment_data["clientPaymentDate"] ? Date.parse(payment_data["clientPaymentDate"]) : nil,
      credit_date: payment_data["creditDate"] ? Date.parse(payment_data["creditDate"]) : nil,
      estimated_credit_date: payment_data["estimatedCreditDate"] ? Date.parse(payment_data["estimatedCreditDate"]) : nil,

      # Payment Method
      billing_type: payment_data["billingType"],
      can_be_paid_after_due_date: payment_data["canBePaidAfterDueDate"],
      pix_transaction: payment_data["pixTransaction"],

      # Description and References
      description: payment_data["description"],
      external_reference: payment_data["externalReference"],
      installment_number: payment_data["installmentNumber"],

      # Document Information
      invoice_url: payment_data["invoiceUrl"],
      bank_slip_url: payment_data["bankSlipUrl"],
      invoice_number: payment_data["invoiceNumber"],
      nosso_numero: payment_data["nossoNumero"],

      # Additional Fees
      discount_value: payment_data.dig("discount", "value"),
      discount_limit_date: payment_data.dig("discount", "limitDate") ? Date.parse(payment_data.dig("discount", "limitDate")) : nil,
      discount_due_date_limit_days: payment_data.dig("discount", "dueDateLimitDays"),
      discount_type: payment_data.dig("discount", "type"),

      fine_value: payment_data.dig("fine", "value"),
      fine_type: payment_data.dig("fine", "type"),

      interest_type: payment_data.dig("interest", "type"),

      # Link to the customer
      customer_id: customer.id,

      # operation processamento_id
      processamento_id: processamento_id
    )

    if cobranca.save
      Rails.logger.info("[#{File.basename(__FILE__)}] Cobranca saved successfully with ID: #{cobranca.id}")

      # Update all RemessaSantanderRegistro records with matching processamento_id
      updated_count = RemessaSantanderRegistro.where(
        processamento_id: processamento_id
      ).update_all(asaas_payment_id: payment_data["id"])

      if updated_count > 0
        Rails.logger.info("[#{File.basename(__FILE__)}] Updated #{updated_count} remessa_santander_registro records with asaas_payment_id: #{payment_data["id"]}")
      else
        Rails.logger.warn("[#{File.basename(__FILE__)}] No remessa_santander_registro records found with processamento_id: #{processamento_id}")
      end

      # cobranca
    else
      Rails.logger.error("[#{File.basename(__FILE__)}] Failed to save cobranca: #{cobranca.errors.full_messages.join(', ')}")
      nil
    end
  end
end
