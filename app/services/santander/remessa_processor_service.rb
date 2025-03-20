# app/services/santander/remessa_processor_service.rb
module Santander
  class RemessaProcessorService
    class ProcessingError < StandardError; end

    def initialize(file_path)
      @file_path = file_path
      @remessa_header = nil
    end

    def process
      header_data = process_header
      registro_data = process_registros(header_data)

      ActiveRecord::Base.transaction do
        create_remessa_header(header_data)
        bulk_insert_registros(registro_data)
      end

      { success: true }
    rescue StandardError => e
      Rails.logger.error "Error processing remessa file: #{e.message}"
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
      @remessa_header = RemessaSantanderHeader.create!(header_data)
      Rails.logger.info "Inserted RemessaHeader with ID: #{@remessa_header.id}"
      @remessa_header
    end

    def bulk_insert_registros(registro_data)
      inserted_count = RemessaSantanderRegistro.insert_all!(
        registro_data.map { |data| data.merge(remessa_santander_header_id: @remessa_header.id) }
      ).count
      Rails.logger.info "Bulk inserted #{inserted_count} RemessaRegistro records"
    end
  end
end
