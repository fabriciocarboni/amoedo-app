# app/services/santander/remessa_trailer_processor_service.rb
module Santander
  class RemessaTrailerProcessorService
    class ParseError < StandardError; end

    def initialize(trailer_line)
      @trailer_line = trailer_line
      @schema = load_schema
    end

    def parse
      @schema.each_with_object({}) do |(field, details), result|
        result[field] = extract_and_process_field(field, details)
      end
    rescue ParseError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Parse error for trailer: #{e.message}"
      raise
    rescue StandardError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Unexpected error processing trailer: #{e.message}"
      raise ParseError, "Failed to process trailer: #{e.message}"
    end

    private

    def load_schema
      YAML.load_file(Rails.root.join("config", "remessa_schema.yml"))["trailer"]
    end

    def extract_and_process_field(field, details)
      value = extract_field_value(field, details)
      process_field(field, value, details)
    end

    def extract_field_value(field, details)
      value = @trailer_line[details["start"] - 1, details["length"]]
      if value.nil? || value.empty?
        raise ParseError, "Missing field #{field} at position #{details['start']}"
      end
      value
    end

    def process_field(field, value, details)
      value = value.strip
      if field == "valor_total_dos_boletos"
        # Convert monetary values (assuming 2 decimal places)
        (value.to_i / 100.0)
      else
        value
      end
    rescue StandardError => e
      Rails.logger.error "[#{File.basename(__FILE__)}] Data conversion error for field #{field}: #{e.message}"
      raise ParseError, "Invalid data format for field #{field}: #{e.message}"
    end
  end
end
