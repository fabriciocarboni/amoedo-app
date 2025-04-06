# app/services/santander/remessa_header_processor_service.rb
module Santander
  class RemessaHeaderProcessorService
    class ParseError < StandardError; end

    def initialize(header_line)
      @header_line = header_line
      @schema = load_schema
    end

    def parse
      @schema.each_with_object({}) do |(field, details), data|
        data[field] = extract_and_process_field(field, details)
      end
    rescue ParseError => e
      Rails.logger.error "Parse error for header: #{e.message}"
      raise
    rescue StandardError => e
      Rails.logger.error "Unexpected error processing header: #{e.message}"
      raise ParseError, "Failed to process header: #{e.message}"
    end

    private

    def load_schema
      YAML.load_file(Rails.root.join("config", "remessa_schema.yml"))["header"]
    end

    def extract_and_process_field(field, details)
      value = extract_field_value(field, details)
      process_field(value, details)
    end

    def extract_field_value(field, details)
      value = @header_line[details["start"] - 1, details["length"]]
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
      raise ParseError, "[#{File.basename(__FILE__)}] Invalid data format for field: #{e.message}"
    end
  end
end
