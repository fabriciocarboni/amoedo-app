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
      all_lines = File.readlines(@file_path)
      header_data = process_header(all_lines.first)
      trailer_data = process_trailer(all_lines.last)
      registro_data = process_registros(header_data, all_lines[1...-1])

      ActiveRecord::Base.transaction do
        create_remessa_header(header_data)
        bulk_insert_registros(registro_data)
        create_remessa_trailer(trailer_data)
      end

      # create cobranca in Asaas
      # This process is commented out for now because Amoedo will not use asaas. this call is responsible to create the
      # cobrancas in asaas.
      # create_cobrancas(registro_data)

      { success: true, processamento_id: @processamento_id }
    rescue StandardError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Error processing remessa file: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
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
      @remessa_header = RemessaSantanderHeader.create!(
        header_data.merge(
          nome_arquivo_remessa: @original_filename,
          processamento_id: @processamento_id
        )
      )
      Rails.logger.info "[#{File.basename(__FILE__)}] Inserted RemessaHeader with ID: #{@remessa_header.id}"
      @remessa_header
    end

    def bulk_insert_registros(registro_data)
      inserted_count = RemessaSantanderRegistro.insert_all!(
        registro_data.map do |data|
          data.merge(
            remessa_santander_header_id: @remessa_header.id,
            nome_arquivo_remessa: @original_filename,
            processamento_id: @processamento_id
          )
        end
      ).count
      Rails.logger.info "[#{File.basename(__FILE__)}] Bulk inserted #{inserted_count} RemessaRegistro records"
    end

    def create_remessa_trailer(trailer_data)
      @remessa_trailer = RemessaSantanderTrailer.create!(
        trailer_data.merge(
          nome_arquivo_remessa: @original_filename,
          processamento_id: @processamento_id
        )
      )
      Rails.logger.info "[#{File.basename(__FILE__)}] Inserted RemessaTrailer with ID: #{@remessa_trailer.id}"
      @remessa_trailer
    end

    # def create_cobrancas(cobrancas)
    #   puts "Entering create_cobrancas method"
    #   processamento_id ||= @processamento_id
    #   results = ::AsaasCobrancaHandlerService.handle_cobrancas(cobrancas, processamento_id)
    #   { success: true, message: "Processed #{results.length} registros" }
    # end
  end
end
