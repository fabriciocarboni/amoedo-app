# app/services/santander/remessa_registro_processor_service.rb
module Santander
  class RemessaRegistroProcessorService
    class ParseError < StandardError; end

    def initialize(registro_line, header_data)
      @registro_line = registro_line
      @header_data = header_data
      @schema = load_schema
    end

    def parse
      data = @schema.each_with_object({}) do |(field, details), parsed_data|
        parsed_data[field] = extract_and_process_field(field, details)
      end

      data
    rescue ParseError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Parse error for registro: #{e.message}"
      raise
    rescue StandardError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Unexpected error processing registro: #{e.message}"
      raise ParseError, "Failed to process registro: #{e.message}"
    end

    private

    def load_schema
      YAML.load_file(Rails.root.join("config", "remessa_schema.yml"))["registro_movimento"]
    end

    def extract_and_process_field(field, details)
      value = extract_field_value(field, details)
      process_field(value, details)
    end

    def extract_field_value(field, details)
      value = @registro_line[details["start"] - 1, details["length"]]
      if value.nil? || value.empty?
        raise ParseError, "Missing field #{field} at position #{details["start"]}"
      end
      value
    end

    def process_field(value, details)
      value = value.strip
      if details["decimal"]
        (value.to_i / (10.0 ** details["decimal"]))
      else
        value
      end
    rescue StandardError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Data conversion error for field: #{e.message}"
      raise ParseError, "Invalid data format for field: #{e.message}"
    end
  end
end
