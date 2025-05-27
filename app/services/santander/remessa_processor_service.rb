# app/services/santander/remessa_processor_service.rb
require "json"
require "securerandom"

module Santander
  class RemessaProcessorService
    def initialize(file_path, original_filename)
      @file_path = file_path
      @original_filename = original_filename
      @processamento_id = SecureRandom.random_number(1_000_000_000)
    end

    # Process the file
    def process
      begin
        # Verificar se o arquivo já foi processado antes
        if RemessaSantanderHeader.exists?(nome_arquivo_remessa: @original_filename)
          return {
            success: false,
            error: "Este arquivo de remessa já foi processado anteriormente.",
            already_processed: true
          }
        end
      end

      all_lines = File.readlines(@file_path, encoding: "ISO-8859-1:UTF-8")
      header_data = process_header(all_lines.first)
      trailer_data = process_trailer(all_lines.last)
      registro_data = process_registros(header_data, all_lines[1...-1])

      bulk_result = nil
      ActiveRecord::Base.transaction do
        create_remessa_header(header_data)
        # bulk_insert_registros(registro_data)
        bulk_result = bulk_insert_registros(registro_data)
        create_remessa_trailer(trailer_data)
      end

      # create cobranca in Asaas
      # This process is commented out for now because Amoedo will not use asaas. this call is responsible to create the
      # cobrancas in asaas.
      # create_cobrancas(registro_data)

      { success: true, processamento_id: @processamento_id, skipped_registros: bulk_result[:skipped] }
    rescue StandardError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Error processing remessa file: #{e.message}"
      # Rails.logger.error e.backtrace.join("\n")
      { success: false, error: "Failed to process remessa file: #{e.message}" }
    end

    private

    def process_header(header_line)
      Santander::RemessaHeaderProcessorService.new(header_line).parse
    end

    def process_trailer(trailer_line)
      Santander::RemessaTrailerProcessorService.new(trailer_line).parse
    end

    def process_registros(header_data, registro_lines)
      registro_lines.map do |line|
        Santander::RemessaRegistroProcessorService.new(line, header_data).parse
      end
    end

    def create_remessa_header(header_data)
      # Garantir que nome_arquivo_remessa não seja nil
      arquivo_nome = header_data["nome_arquivo_remessa"].presence || @original_filename

      if arquivo_nome.nil?
        Rails.logger.error "[#{File.basename(__FILE__)}] Nome do arquivo de remessa não pode ser nulo"
        raise ArgumentError, "Nome do arquivo de remessa não pode ser nulo"
      end

      @remessa_header = RemessaSantanderHeader.find_or_create_by(
        nome_arquivo_remessa: arquivo_nome
      ) do |header|
        header.assign_attributes(
          header_data.merge(
            nome_arquivo_remessa: @original_filename,
            processamento_id: @processamento_id
          )
        )
      end

      if @remessa_header.persisted? && @remessa_header.previously_new_record?
        Rails.logger.info "[#{File.basename(__FILE__)}] Inserted new RemessaHeader with nome_arquivo_remessa: #{@remessa_header.nome_arquivo_remessa}"
      else
        Rails.logger.info "[#{File.basename(__FILE__)}] Found existing RemessaHeader with nome_arquivo_remessa: #{@remessa_header.nome_arquivo_remessa}"
      end

      @remessa_header
    end

    def bulk_insert_registros(registro_data)
      result = RemessaSantanderRegistro.insert_all(
        registro_data.map do |data|
          data.merge(
            remessa_santander_header_id: @remessa_header.id,
            nome_arquivo_remessa: @original_filename,
            processamento_id: @processamento_id
          )
        end,
        unique_by: :identificacao_do_boleto_no_banco
      )
        inserted_count = result.length
        skipped_count = registro_data.size - inserted_count
        Rails.logger.info "[#{File.basename(__FILE__)}] Bulk inserted #{inserted_count} RemessaRegistro records, skipped #{skipped_count} duplicates"
        { inserted: inserted_count, skipped: skipped_count }
    end

    def create_remessa_trailer(trailer_data)
      # First check if a trailer already exists for this header
      existing_trailer = RemessaSantanderTrailer.find_by(remessa_santander_header_id: @remessa_header.id)

      if existing_trailer
        # Trailer already exists for this header, so it has been processed before
        @remessa_trailer = existing_trailer
        Rails.logger.info "[#{File.basename(__FILE__)}] Found existing RemessaTrailer with ID: #{@remessa_trailer.id} for header ID: #{@remessa_header.id}. Skipping processing."
        @remessa_trailer
      else
        # No trailer exists for this header, create a new one
        @remessa_trailer = RemessaSantanderTrailer.new(
          trailer_data.merge(
            remessa_santander_header_id: @remessa_header.id,
            nome_arquivo_remessa: @original_filename,
            processamento_id: @processamento_id
          )
        )

        if @remessa_trailer.save
          Rails.logger.info "[#{File.basename(__FILE__)}] Inserted new RemessaTrailer with ID: #{@remessa_trailer.id} for header ID: #{@remessa_header.id}"
        else
          Rails.logger.error "[#{File.basename(__FILE__)}] Failed to create RemessaTrailer: #{@remessa_trailer.errors.full_messages.join(', ')}"
        end

        @remessa_trailer
      end
    end

    # def create_cobrancas(cobrancas)
    #   puts "Entering create_cobrancas method"
    #   processamento_id ||= @processamento_id
    #   results = ::AsaasCobrancaHandlerService.handle_cobrancas(cobrancas, processamento_id)
    #   { success: true, message: "Processed #{results.length} registros" }
    # end
  end
end
