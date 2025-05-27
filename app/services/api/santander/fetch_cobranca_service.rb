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

      # Directory to store downloaded boletos (Potentially used by BoletoStorageService)
      BOLETOS_DIR = Rails.root.join("storage", "boletos")

      def self.get_cobrancas(cpf_cnpj_raw, vencimento = nil)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) # Record start time

        # Use o vencimento informado ou o mês atual como padrão
        month_year = vencimento.present? ? vencimento : Time.current.strftime("%m%y")

        if cpf_cnpj_raw.blank?
          # Using ArgumentError for programmer error (blank input not expected path)
          raise ArgumentError, "CPF/CNPJ cannot be blank"
        end

        clean_cpfcnpj = clean_cpf_cnpj(cpf_cnpj_raw)

        # Query base
        query = RemessaSantanderRegistro.where(numero_de_inscricao_do_pagador: clean_cpfcnpj)

        # Adiciona a condição de vencimento
        query = query.where("SUBSTRING(data_de_vencimento_do_boleto, 3, 4) = ?", month_year)

        clients = query

        unless clients.exists?
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "customer_notfound",
            msg: "Cliente não encontrado com o CPF/CNPJ informado.",
            tempo_de_execucao: "#{duration} seconds"
          }
        end

        client_for_beneficiary_info = clients.find { |c| c.numero_de_inscricao_do_beneficiario.present? }

        unless client_for_beneficiary_info
          log_msg = "[#{File.basename(__FILE__)}] No client record found with 'numero_de_inscricao_do_beneficiario' for CPF/CNPJ #{clean_cpfcnpj}. Client IDs: #{clients.map(&:id).join(', ')}"
          Rails.logger.warn("\n#{log_msg}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_configuration",
            msg: "Dados de configuração do beneficiário ausentes para este cliente.",
            tempo_de_execucao: "#{duration} seconds"
          }
        end
        inscricao_beneficiario = client_for_beneficiary_info.numero_de_inscricao_do_beneficiario

        subsidiary_key = HttpClientHelper.determine_subsidiary_key(inscricao_beneficiario)
        credentials = HttpClientHelper.client_credentials_for(subsidiary_key) # Can raise ArgumentError
        HttpClientHelper.log_credentials_status(subsidiary_key, credentials) # Assumes it handles nil credentials gracefully if applicable

        token = nil
        begin
          token = AuthService.fetch_token(subsidiary_key)
          Rails.logger.info("\n[#{File.basename(__FILE__)}] ########### Token fetched successfully for subsidiary #{subsidiary_key} (CPF/CNPJ #{clean_cpfcnpj})")
        rescue ArgumentError => e # Configuration errors from AuthService or HttpClientHelper
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Configuration error fetching token for subsidiary #{subsidiary_key} (CPF/CNPJ #{clean_cpfcnpj}): #{e.message}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_configuration",
            msg: "Erro de configuração interna ao obter token. Contate o suporte.",
            tempo_de_execucao: "#{duration} seconds" # Add here too
          }
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Network/SSL error fetching token for subsidiary #{subsidiary_key} (CPF/CNPJ #{clean_cpfcnpj}): #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_communication",
            msg: "Erro de comunicação com o banco ao obter token. Tente novamente mais tarde.",
            tempo_de_execucao: "#{duration} seconds"
          }
        rescue StandardError => e
          Rails.logger.error("\n[#{File.basename(__FILE__)}] Unexpected error fetching token for subsidiary #{subsidiary_key} (CPF/CNPJ #{clean_cpfcnpj}): #{e.message}\n#{e.backtrace.join("\n")}")
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)
          return {
            status: "error_unknown",
            msg: "Erro desconhecido ao obter token. Contate o suporte.",
            tempo_de_execucao: "#{duration} seconds" # Add here too
          }
        end

        processed_boletos_list = []
        processed_count = 0
        error_count = 0

        clients.each_with_index do |client_record, index|
          Rails.logger.info("\n[#{File.basename(__FILE__)}] Processing boleto record ##{index + 1}/#{clients.size} for client ID #{client_record.id}, CPF/CNPJ #{clean_cpfcnpj}")

          unless client_record.identificacao_do_boleto_no_banco.present?
            Rails.logger.info("\n[#{File.basename(__FILE__)}] Client ID #{client_record.id} (CPF/CNPJ #{clean_cpfcnpj}) has no 'identificacao_do_boleto_no_banco'. Skipping.")
            error_count += 1
            next
          end

          begin
            boleto_data = process_single_boleto_record(
              client_record,
              token,
              subsidiary_key,
              credentials,
              clean_cpfcnpj # Pass the cleaned CPF/CNPJ for API body
            )
            processed_boletos_list << boleto_data
            processed_count += 1
          rescue ArgumentError => e # Date parsing or other argument errors within process_single_boleto_record
            Rails.logger.error("\n[#{File.basename(__FILE__)}] Argument error processing boleto for client ID #{client_record.id} (CPF/CNPJ #{clean_cpfcnpj}, NossoNumero #{client_record.identificacao_do_boleto_no_banco}): #{e.message}")
            error_count += 1
          rescue ::Santander::BoletoStorageService::StorageError => e # Custom error from storage service
            Rails.logger.error("\n[#{File.basename(__FILE__)}] Storage error for client ID #{client_record.id} (CPF/CNPJ #{clean_cpfcnpj}, NossoNumero #{client_record.identificacao_do_boleto_no_banco}): #{e.message}")
            error_count += 1
          # Catch specific network/SSL errors that might bubble up from get_boleto_link
          rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
                 Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
            Rails.logger.error("\n[#{File.basename(__FILE__)}] Network/SSL error processing boleto for client ID #{client_record.id} (CPF/CNPJ #{clean_cpfcnpj}, NossoNumero #{client_record.identificacao_do_boleto_no_banco}): #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
            error_count += 1
          rescue StandardError => e # Catch other errors from get_boleto_link or within process_single_boleto_record
            log_prefix = "[#{File.basename(__FILE__)}] Errorxyz processing boleto for client ID #{client_record.id} (CPF/CNPJ #{clean_cpfcnpj}, NossoNumero #{client_record.identificacao_do_boleto_no_banco})"
            # Rails.logger.error("\n#{log_prefix}: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
            error_count += 1
            if e.message.match?(/Failed to get boleto link/i) || e.message.match?(/Boleto link missing/i)
              Rails.logger.warn("\n#{log_prefix}: Boleto link fetch failed, possibly cancelled/paid or data mismatch with bank.")
            end
          end
        end

        Rails.logger.info("\n[#{File.basename(__FILE__)}] Finished processing for CPF/CNPJ #{clean_cpfcnpj}. Successfully processed: #{processed_count}, Errors: #{error_count}.")

        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = (end_time - start_time).round(2)
        execution_time_str = "#{duration} seconds"

        if processed_boletos_list.any?
          {
            status: "client_slips",
            tempo_de_execucao: execution_time_str,
            quantidade_boletos: processed_boletos_list.size.to_s,
            data: processed_boletos_list
          }
        else
          # No boletos were successfully processed
          if clients.all? { |c| c.identificacao_do_boleto_no_banco.blank? }
            { status: "customer_noslips_error",
              quantidade_boletos: "0",
              tempo_de_execucao: execution_time_str,
              msg: "Dados do boleto incompletos para o cliente (nenhum identificador de boleto encontrado).",
              data: []
            }
          else
            # Attempts were made (IDs existed), but all failed for other reasons.
            { status: "client_noslips",
              quantidade_boletoss: "0",
              tempo_de_execucao: execution_time_str,
              msg: "Não foi encontrado nenhum boleto para o CPF/CNPJ informado. Os boletos podem estar cancelados ou liquidados.",
              dados: []
          }
          end
        end

      # Global rescue blocks for issues not caught by more specific handlers (e.g., during setup before loop)
      rescue ArgumentError => e
        Rails.logger.error("\n[#{File.basename(__FILE__)}] Configuration error in #{self.name}##{__method__} for CPF/CNPJ #{cpf_cnpj_raw}: #{e.message}")
        exec_time_str_rescue = defined?(start_time) ? "#{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)} seconds" : "N/A"
        { status: "error_configuration", msg: "Erro de configuração interna. Contate o suporte.", tempo_de_execucao: exec_time_str_rescue }
      rescue StandardError => e
        Rails.logger.error("\n[#{File.basename(__FILE__)}] Unexpected global error in #{self.name}##{__method__} for CPF/CNPJ #{cpf_cnpj_raw}: #{e.message}\n#{e.backtrace.join("\n")}")
        exec_time_str_rescue = defined?(start_time) ? "#{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)} seconds" : "N/A"
        { status: "error_unknown", msg: "Ocorreu um erro inesperado. Contate o suporte.", tempo_de_execucao: exec_time_str_rescue }
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

        # Ensure filename uniqueness, especially if multiple boletos have same payer name and due date
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
