# app/services/santander/remessa_upload_service.rb
module Santander
  class RemessaUploadService
    def self.call(file)
      new(file).call
    end

    def initialize(file)
      @file = file
    end

    def call
      return { success: false, error: "Por favor, selecione um arquivo para upload." } if @file.nil?

      file_path = save_temporary_file
      process_result = process_remessa(file_path)
      delete_temporary_file(file_path)

      process_result
    rescue StandardError => e
      { success: false, error: "Erro ao processar arquivo: #{e.message}" }
    end

    private

    def save_temporary_file
      file_path = Rails.root.join("tmp", @file.original_filename)
      File.open(file_path, "wb") { |file| file.write(@file.read) }
      file_path
    end

    def process_remessa(file_path)
      processor = Santander::RemessaProcessorService.new(file_path)
      processor.process
    end

    def delete_temporary_file(file_path)
      File.delete(file_path)
    end
  end
end
