# app/services/api/santander/fetch_cobranca_service.rb
module Api
  module Santander
    class FetchCobrancaService
      # Removed httparty as it's no longer used directly in this service
      # require "httparty"
      require "tempfile"
      require "openssl"
      require "open-uri"
      require "fileutils"
      require "net/http" # Now definitely needed
      require "uri"     # For URI.parse
      require "json"    # For JSON.parse and .to_json
      require "date"

      # Directory to store downloaded boletos
      BOLETOS_DIR = Rails.root.join("storage", "boletos")


      def self.get_cobrancas(cpf_cnpj)
        if cpf_cnpj.blank?
          raise ArgumentError, "CPF/CNPJ cannot be blank"
        end

        clean_cpfcnpj = clean_cpf_cnpj(cpf_cnpj)
        # puts("clean_cpfcnpj: #{clean_cpfcnpj}")
        # exit

        client = RemessaSantanderRegistro.find_by(numero_de_inscricao_do_pagador: clean_cpfcnpj)

        unless client
          return { status: "customer_notfound", msg: "Cliente não encontrado com o CPF/CNPJ informado." }
        end

        unless client.identificacao_do_boleto_no_banco.present?
             Rails.logger.info("\n[#{File.basename(__FILE__)}] Client found for CPF/CNPJ #{cpf_cnpj}, but no 'identificacao_do_boleto_no_banco'. Client ID: #{client.id}")
             return { status: "customer_noslips", msg: "Dados do boleto incompletos para o cliente.", data: [] }
        end

        conta_movimento = client.conta_movimento_beneficiario
        identificacao_boleto = client.identificacao_do_boleto_no_banco
        inscricao_beneficiario = client.numero_de_inscricao_do_beneficiario
        raw_vencimento_string = client.data_de_vencimento_do_boleto

        # --- PARSE THE DATE STRING ---
        begin
          # Assuming DDMMYY format for "150625"
          # Date.strptime will raise ArgumentError if format doesn't match
          parsed_vencimento_date = Date.strptime(raw_vencimento_string, "%d%m%y")
        rescue ArgumentError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Failed to parse data_de_vencimento_do_boleto '#{raw_vencimento_string}': #{e.message}")
          # Handle this error appropriately. Maybe return an error, or use a default/nil date.
          # For now, let's re-raise or return an error status, as a valid filename is important.
          return { status: "error_invalid_date", msg: "Data de vencimento inválida no registro do cliente: #{raw_vencimento_string}" }
        end
        # --- END PARSE THE DATE STRING ---

        subsidiary_key = HttpClientHelper.determine_subsidiary_key(inscricao_beneficiario)
        # We need credentials for the app_key (client_id) and for the PFX file for Net::HTTP
        credentials = HttpClientHelper.client_credentials_for(subsidiary_key)
        HttpClientHelper.log_credentials_status(subsidiary_key, credentials)

        begin
          token = AuthService.fetch_token(subsidiary_key) # This now uses Net::HTTP

          boleto_response = get_boleto_link(
            token,
            subsidiary_key, # Needed for PFX loading
            credentials[:client_id], # This is the app_key
            credentials[:pfx_path], # Pass PFX path
            credentials[:pfx_password], # Pass PFX password
            conta_movimento,
            identificacao_boleto,
            cpf_cnpj
          )

          santander_link = boleto_response["link"]
          unless santander_link
            Rails.logger.error("\n[#{File.basename(__FILE__)}] Boleto link not found in response for CPF/CNPJ #{cpf_cnpj}. Response: #{boleto_response}")
            return {
              status: "client_noslips",
              msg: "Não foi possível obter o link do boleto. Verifique os dados ou tente novamente mais tarde."
            }
          end

          pdf_filename = "#{client.nome_do_pagador.parameterize}_#{parsed_vencimento_date.strftime('%Y%m%d')}.pdf"

          storage_service = ::Santander::BoletoStorageService.new(santander_link, pdf_filename)
          storage_result = storage_service.call # This will raise an error on failure

          # Format the parsed_vencimento_date for the response
          formatted_vencimento = parsed_vencimento_date.strftime("%d/%m/%Y") # DD/MM/YYYY

          formatted_valor = ActionController::Base.helpers.number_to_currency(
            client.valor_nominal_do_boleto,
            unit: "R$",
            separator: ",",
            delimiter: "."
          )

          {
            status: "client_slips",
            dados: {
              nome_client: client.nome_do_pagador,
              cpf_cnpj: cpf_cnpj,
              vencimento: formatted_vencimento, # Use the formatted string
              valor: formatted_valor,
              boleto_url: storage_result[:active_storage_url] # Get URL from service result
            }
          }
        rescue ArgumentError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Configuration error in #{self.name}##{__method__}: #{e.message}")
          { status: "error_configuration", msg: "Erro de configuração interna. Contate o suporte." }
        # Catch specific network/SSL errors that might bubble up from AuthService or get_boleto_link
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Network/SSL communication error in #{self.name}##{__method__} for CPF/CNPJ #{cpf_cnpj}: #{e.class} - #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          { status: "error_communication", msg: "Erro de comunicação com o banco. Tente novamente mais tarde." }
        rescue StandardError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Unexpected error in #{self.name}##{__method__} for CPF/CNPJ #{cpf_cnpj}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          msg = "Não foi encontrado boleto para o cpf_cnpj informado. Entrar em contato com o suporte financeiro."
          msg += " Este boleto pode estar cancelado ou liquidado." if e.message.match?(/Failed to get boleto link/i)
          { status: "client_noslips_error", msg: msg }
        end
      end

      private

      def self.clean_cpf_cnpj(cpf_cnpj)
        cpf_cnpj.gsub(/[^\d]/, "")
      end

      def self.get_boleto_link(token, subsidiary_key, app_key, pfx_path, pfx_password, conta_movimento, identificacao_boleto, cpf_cnpj)
        boleto_url_string = "#{HttpClientHelper.base_uri}/collection_bill_management/v2/bills/#{identificacao_boleto}.#{conta_movimento}/bank_slips"
        Rails.logger.info("\n[#{File.basename(__FILE__)}] Requesting boleto from: #{boleto_url_string} for CPF/CNPJ: #{cpf_cnpj} using Net::HTTP\n")

        uri = URI.parse(boleto_url_string)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        begin
          p12 = OpenSSL::PKCS12.new(File.read(pfx_path), pfx_password)
          http.cert = p12.certificate
          http.key = p12.key
        rescue OpenSSL::PKCS12::PKCS12Error => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Failed to load PKCS12 certificate for Net::HTTP (get_boleto_link): #{e.message}")
          raise "Failed to load PKCS12 certificate for #{subsidiary_key} (get_boleto_link): #{e.message}"
        end

        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: Review for production
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER # TODO: Review for production
        # if http.verify_mode == OpenSSL::SSL::VERIFY_PEER
        #   http.ca_file = Rails.root.join('config', 'certificates', 'server_ca_bundle.pem').to_s
        # end

        http.set_debug_output($stdout) if ENV["NET_HTTP_DEBUG"] == "true" || false

        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = { payerDocumentNumber: clean_cpf_cnpj(cpf_cnpj) }.to_json
        request["Authorization"] = "Bearer #{token}"
        request["X-Application-Key"] = app_key
        request["Content-Type"] = "application/json"
        request["Accept"] = "application/json" # Good practice to set Accept header

        begin
          Rails.logger.info("\n[#{File.basename(__FILE__)}] Sending Net::HTTP POST request for boleto to #{uri.host}#{uri.path}")
          response = http.request(request)

          Rails.logger.info("\n[#{File.basename(__FILE__)}] Net::HTTP Boleto response code: #{response.code}")
          # Rails.logger.debug("\n[#{File.basename(__FILE__)}] Net::HTTP Boleto response body: #{response.body}")

          unless response.is_a?(Net::HTTPSuccess)
            error_message = "Failed to get boleto link (Net::HTTP): #{response.code} - #{response.message}. Body: #{response.body}"
            Rails.logger.error("\n[#{File.basename(__FILE__)}] #{error_message}")
            response.each_header { |k, v| Rails.logger.error("\n[#{File.basename(__FILE__)}] Boleto Response Header: #{k}: #{v}") }
            raise StandardError, error_message # This will be caught by the main rescue block
          end

          JSON.parse(response.body)

        rescue JSON::ParserError => e
          error_message = "Failed to parse Santander boleto response (Net::HTTP). Body: #{response&.body}. Error: #{e.message}"
          Rails.logger.error("\n[#{File.basename(__FILE__)}] #{error_message}")
          raise StandardError, error_message # Re-raise to be caught by the main rescue block
        # Specific network/SSL errors are already handled in the main get_cobrancas method
        # but re-raising here allows them to be caught there with more context if needed.
        # Or, you could handle them here and return a specific error structure.
        ensure
            http.finish if http.started?
        end
      end
    end
  end
end
