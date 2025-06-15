# app/services/api/santander/fetch_cobranca_service.rb
module Api
  module Santander
    class FetchCobrancaService
      require "tempfile"
      require "openssl"
      require "open-uri"
      require "fileutils"
      require "net/http"
      require "uri"
      require "json"
      require "date"
      require_dependency "santander/boleto_storage_service"

      BOLETOS_DIR = Rails.root.join("storage", "boletos")

      def self.get_single_cobranca(cpf_cnpj_raw, nosso_numero)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        if cpf_cnpj_raw.blank? || nosso_numero.blank?
          raise ArgumentError, "CPF/CNPJ e Nosso Número são obrigatórios"
        end

        clean_cpfcnpj = clean_cpf_cnpj(cpf_cnpj_raw)

        # Find specific boleto record
        client_record = RemessaSantanderRegistro
          .where(numero_de_inscricao_do_pagador: clean_cpfcnpj)
          .where(identificacao_do_boleto_no_banco: nosso_numero.to_i)
          .first

        unless client_record
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "boleto_notfound",
            tempo_de_execucao: "#{duration} seconds",
            msg: "Boleto não encontrado para o CPF/CNPJ e Nosso Número informados."
          }
        end

        # Get beneficiary info for API credentials
        unless client_record.numero_de_inscricao_do_beneficiario.present?
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_configuration",
            tempo_de_execucao: "#{duration} seconds",
            msg: "Dados de configuração do beneficiário ausentes para este boleto."
          }
        end

        inscricao_beneficiario = client_record.numero_de_inscricao_do_beneficiario
        subsidiary_key = HttpClientHelper.determine_subsidiary_key(inscricao_beneficiario)
        credentials = HttpClientHelper.client_credentials_for(subsidiary_key)

        # Get authentication token
        token = nil
        begin
          token = AuthService.fetch_token(subsidiary_key)
          Rails.logger.info("\n[#{File.basename(__FILE__)}] Token fetched successfully for subsidiary #{subsidiary_key}")
        rescue ArgumentError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Configuration error: #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_configuration",
            msg: "Erro de configuração interna ao obter token.",
            tempo_de_execucao: "#{duration} seconds"
          }
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Network/SSL error: #{e.class} - #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_communication",
            msg: "Erro de comunicação com o banco.",
            tempo_de_execucao: "#{duration} seconds"
          }
        rescue StandardError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Unexpected error: #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_unknown",
            msg: "Erro desconhecido ao obter token.",
            tempo_de_execucao: "#{duration} seconds"
          }
        end

        # Process the single boleto
        begin
          boleto_data = process_single_boleto_record(
            client_record,
            token,
            subsidiary_key,
            credentials,
            clean_cpfcnpj
          )

          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)

          {
            status: "boleto_processed",
            tempo_de_execucao: "#{duration} seconds",
            data: boleto_data
          }

        rescue ArgumentError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Argument error: #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          {
            status: "error_data",
            msg: "Erro nos dados do boleto: #{e.message}",
            tempo_de_execucao: "#{duration} seconds"
          }
        rescue ::Santander::BoletoStorageService::StorageError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Storage error: #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          {
            status: "error_storage",
            msg: "Erro ao armazenar boleto: #{e.message}",
            tempo_de_execucao: "#{duration} seconds"
          }
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Network/SSL error processing boleto: #{e.class} - #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          {
            status: "error_communication",
            msg: "Erro de comunicação com o banco ao processar boleto.",
            tempo_de_execucao: "#{duration} seconds"
          }
        rescue StandardError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Unexpected error processing boleto: #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          {
            status: "error_unknown",
            msg: "Erro desconhecido ao processar boleto.",
            tempo_de_execucao: "#{duration} seconds"
          }
        end

      rescue ArgumentError => e
        Rails.logger.error("\n[#{File.basename(__FILE__)}] Configuration error: #{e.message}")
        exec_time_str = defined?(start_time) ? "#{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)} seconds" : "N/A"
        { status: "error_configuration", msg: "Erro de configuração interna.", tempo_de_execucao: exec_time_str }
      rescue StandardError => e
        Rails.logger.error("\n[#{File.basename(__FILE__)}] Unexpected global error: #{e.message}")
        exec_time_str = defined?(start_time) ? "#{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)} seconds" : "N/A"
        { status: "error_unknown", msg: "Ocorreu um erro inesperado.", tempo_de_execucao: exec_time_str }
      end

      private

      def self.process_single_boleto_record(client_record, token, subsidiary_key, credentials, cpf_cnpj_cleaned_for_api)
        identificacao_boleto = client_record.identificacao_do_boleto_no_banco
        conta_movimento = client_record.conta_movimento_beneficiario
        raw_vencimento_string = client_record.data_de_vencimento_do_boleto

        begin
          parsed_vencimento_date = Date.strptime(raw_vencimento_string, "%d%m%y")
        rescue ArgumentError => e
          # Re-raise to be caught by the per-boleto error handler in the main loop
          raise ArgumentError, "Data de vencimento '#{raw_vencimento_string}' inválida: #{e.message}"
        end

        boleto_response = get_boleto_link(
          token,
          subsidiary_key,
          credentials[:client_id], # app_key
          credentials[:pfx_path],
          credentials[:pfx_password],
          conta_movimento,
          identificacao_boleto,
          cpf_cnpj_cleaned_for_api # This is the payer's document number for the API
        ) # Raises errors on failure

        santander_link = boleto_response["link"] # get_boleto_link now ensures this exists or raises

        # Ensure filename uniqueness, especially if multip le boletos have same payer name and due date
        pdf_filename = "#{client_record.nome_do_pagador.parameterize}_#{parsed_vencimento_date.strftime('%Y%m%d')}_#{identificacao_boleto}.pdf"

        storage_service = ::Santander::BoletoStorageService.new(santander_link, pdf_filename)
        storage_result = storage_service.call # Raises StorageError on failure

        formatted_vencimento = parsed_vencimento_date.strftime("%d/%m/%Y")
        formatted_valor = ActionController::Base.helpers.number_to_currency(
          client_record.valor_nominal_do_boleto,
          unit: "R$",
          separator: ",",
          delimiter: "."
        )

        {
          nome_client: client_record.nome_do_pagador,
          cpf_cnpj: format_cpf_cnpj_for_display(cpf_cnpj_cleaned_for_api), # Display formatted
          vencimento: formatted_vencimento,
          valor: formatted_valor,
          nosso_numero: client_record.identificacao_do_boleto_no_banco,
          boleto_url: storage_result[:active_storage_url]
        }
      end

      def self.clean_cpf_cnpj(cpf_cnpj)
        cpf_cnpj.to_s.gsub(/[^\d]/, "")
      end

      def self.format_cpf_cnpj_for_display(cleaned_cpf_cnpj)
        return cleaned_cpf_cnpj if cleaned_cpf_cnpj.blank? # Handle blank case
        if cleaned_cpf_cnpj.length == 11
          cleaned_cpf_cnpj.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4') # CPF
        elsif cleaned_cpf_cnpj.length == 14
          cleaned_cpf_cnpj.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5') # CNPJ
        else
          cleaned_cpf_cnpj # Return as is if not a standard length
        end
      end

      def self.get_boleto_link(token, subsidiary_key, app_key, pfx_path, pfx_password, conta_movimento, identificacao_boleto, cpf_cnpj_cleaned_for_api_body)
        boleto_url_string = "#{HttpClientHelper.base_uri}/collection_bill_management/v2/bills/#{identificacao_boleto}.#{conta_movimento}/bank_slips"
        log_prefix = "[#{File.basename(__FILE__)}] get_boleto_link (NossoNumero: #{identificacao_boleto}, PayerDoc: #{cpf_cnpj_cleaned_for_api_body})"
        # Rails.logger.info("\n#{log_prefix} Requesting from: #{boleto_url_string}")

        uri = URI.parse(boleto_url_string)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        begin
          p12 = OpenSSL::PKCS12.new(File.read(pfx_path), pfx_password)
          http.cert = p12.certificate
          http.key = p12.key
        rescue OpenSSL::PKCS12::PKCS12Error => e
          Rails.logger.error("\n#{log_prefix} Failed to load PKCS12 certificate for Net::HTTP (subsidiary #{subsidiary_key}): #{e.message}")
          raise StandardError, "Falha ao carregar certificado PKCS12 (subsidiary #{subsidiary_key}): #{e.message}" # Re-raise as StandardError to be caught by caller
        rescue Errno::ENOENT => e # PFX file not found
           Rails.logger.error("\n#{log_prefix} PFX file not found at path '#{pfx_path}' for subsidiary #{subsidiary_key}: #{e.message}")
           raise StandardError, "Arquivo PFX não encontrado para subsidiary #{subsidiary_key}: #{e.message}"
        end

        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.set_debug_output($stdout) if ENV["NET_HTTP_DEBUG"] == "true"

        request_body = { payerDocumentNumber: cpf_cnpj_cleaned_for_api_body }.to_json
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = request_body
        request["Authorization"] = "Bearer #{token}"
        request["X-Application-Key"] = app_key
        request["Content-Type"] = "application/json"
        request["Accept"] = "application/json"

        response_body_for_error_logging = ""
        begin
          # Rails.logger.info("\n#{log_prefix} Sending Net::HTTP POST request to #{uri.host}#{uri.path} with body: #{request_body}")
          response = http.request(request)
          response_body_for_error_logging = response.body # Store for potential error logging

          # Rails.logger.info("\n#{log_prefix} Net::HTTP Boleto response code: #{response.code}")

          unless response.is_a?(Net::HTTPSuccess)
            error_message = "Failed to get boleto link (Net::HTTP): #{response.code} - #{response.message}. Body: #{response_body_for_error_logging}"
            Rails.logger.error("\n#{log_prefix} #{error_message}")
            response.each_header { |k, v| Rails.logger.error("\n#{log_prefix} Response Header: #{k}: #{v}") }
            raise StandardError, error_message # Caught by process_single_boleto_record's error handling
          end

          parsed_response = JSON.parse(response.body)
          unless parsed_response.key?("link") && parsed_response["link"].present?
            error_message = "Boleto link missing or empty in successful response from Santander. Body: #{response.body}"
            Rails.logger.error("\n#{log_prefix} #{error_message}")
            raise StandardError, error_message # Treat as an error
          end
          parsed_response

        rescue JSON::ParserError => e
          error_message = "Failed to parse Santander boleto response (Net::HTTP). Body: #{response_body_for_error_logging}. Error: #{e.message}"
          Rails.logger.error("\n#{log_prefix} #{error_message}")
          raise StandardError, error_message # Re-raise to be caught by caller
        ensure
          http.finish if http && http.started?
        end
      end
    end
  end
end
