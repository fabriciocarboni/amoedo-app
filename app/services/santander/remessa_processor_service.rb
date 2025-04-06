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

    def process
      header_data = process_header
      registro_data = process_registros(header_data)

      ActiveRecord::Base.transaction do
        create_remessa_header(header_data)
        bulk_insert_registros(registro_data)
      end

      # handle_customers(registro_data)

      { success: true }
    rescue StandardError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Error processing remessa file: #{e.message}"
      { success: false, error: "Failed to process remessa file: #{e.message}" }
    end

    private

    def process_header
      header_line = File.open(@file_path, &:gets)
      Santander::RemessaHeaderProcessorService.new(header_line).parse
    end

    def process_registros(header_data)
      File.open(@file_path).each_line.drop(1).map do |line|
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

    def handle_customers(registro_data)
      unique_customers = registro_data.uniq { |data| data["numero_de_inscricao_do_pagador"] }
      customer_data = unique_customers.map do |data|
        {
          cpf_cnpj: data["numero_de_inscricao_do_pagador"],
          name: data["nome_do_pagador"]
        }
      end

      CustomerHandlingService.handle_customers(customer_data)
    end
  end
end
