# app/services/santander/boleto_storage_service.rb
require "fileutils"
require "net/http" # For downloading
require "openssl"  # For SSL context if needed, and verify_mode constants
require "uri"      # For URI.parse

module Santander
  class BoletoStorageService
    class StorageError < StandardError; end
    # Directory to store downloaded boletos temporarily before ActiveStorage upload
    TEMP_BOLETOS_DIR = Rails.root.join("storage", "boletos", "santander")

    # Initializes the service.
    # @param download_url_from_bank [String] The URL provided by the bank to download the PDF.
    # @param desired_filename_base [String] The base filename (e.g., "client-name_20250115.pdf").
    def initialize(download_url_from_bank, desired_filename_base)
      @download_url_from_bank = download_url_from_bank
      @desired_filename_base = desired_filename_base # Should already include .pdf
      @timestamp = Time.now.strftime("%Y%m%d%H%M%S%L")
      @unique_filename_with_ext = "#{@timestamp}_#{@desired_filename_base}"
      @local_temp_path = File.join(TEMP_BOLETOS_DIR, @unique_filename_with_ext)
    end

    # Executes the download and storage process.
    # @return [Hash] A hash containing :local_path and :active_storage_url on success.
    # @raise [StandardError] or specific errors on failure.
    def call
      ensure_directory_exists
      download_file_with_net_http # Renamed to be explicit
      active_storage_url = store_in_active_storage

      {
        local_path: @local_temp_path,
        active_storage_url: active_storage_url
      }
    end

    private

    def ensure_directory_exists
      FileUtils.mkdir_p(TEMP_BOLETOS_DIR) unless Dir.exist?(TEMP_BOLETOS_DIR)
    end

    # THIS METHOD USES Net::HTTP
    def download_file_with_net_http
      Rails.logger.info("[#{File.basename(__FILE__)}] Attempting to download boleto using Net::HTTP.")
      Rails.logger.info("[#{File.basename(__FILE__)}] Source URL: #{@download_url_from_bank}")
      Rails.logger.info("[#{File.basename(__FILE__)}] Target local path: #{@local_temp_path}\n")

      uri = URI.parse(@download_url_from_bank)
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER # Recommended for public URLs
        # http.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE # Usually not needed if system CAs are up to date
      end

      http.open_timeout = 30  # seconds for connection
      http.read_timeout = 120 # Increased read timeout

      # Enable Net::HTTP debug output specifically for this download if needed
      # To use, set ENV['NET_HTTP_DEBUG_DOWNLOAD'] = 'true' before running
      # http.set_debug_output($stdout) if ENV['NET_HTTP_DEBUG_DOWNLOAD'] == 'true'

      request = Net::HTTP::Get.new(uri.request_uri) # GET request for download
      request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
      request["Accept"] = "*/*"
      request["Accept-Encoding"] = "identity" # Ask for uncompressed

      begin
        http.request(request) do |response| # Block form handles connection closing
          case response
          when Net::HTTPSuccess
            File.open(@local_temp_path, "wb") do |output_file|
              response.read_body do |chunk| # Stream the body directly to file
                output_file.write(chunk)
              end
            end
            Rails.logger.info("[#{File.basename(__FILE__)}] Boleto successfully downloaded (Net::HTTP) to: #{@local_temp_path}")
          when Net::HTTPRedirection
            new_location = response["location"]
            Rails.logger.warn("[#{File.basename(__FILE__)}] Download URL redirected to: #{new_location}. This service does not auto-follow redirects for downloads.")
            raise "Download failed: URL redirected to #{new_location} (auto-redirect not implemented for Net::HTTP download)"
          else
            # Handle other non-success HTTP responses
            body_sample = response.body&.slice(0, 1024)
            error_message = "HTTP #{response.code} #{response.message}. Body sample: #{body_sample}"
            Rails.logger.error("[#{File.basename(__FILE__)}] Failed to download boleto (Net::HTTP): #{error_message}")
            response.each_header { |k, v| Rails.logger.error("Header: #{k}: #{v}") }
            raise "Failed to download boleto from Santander: #{error_message}"
          end
        end
      rescue Net::ReadTimeout, Net::OpenTimeout => e
        handle_download_error(e, "Timeout (Net::HTTP)")
      rescue OpenSSL::SSL::SSLError => e
        handle_download_error(e, "SSL Error (Net::HTTP)")
      rescue SocketError => e # Catch DNS resolution errors, etc.
        handle_download_error(e, "Socket Error (Net::HTTP)")
      rescue SystemCallError => e # Catch lower-level system call errors (e.g. Errno::ECONNREFUSED)
        handle_download_error(e, "System Call Error (Net::HTTP)")
      rescue StandardError => e
        handle_download_error(e, "General Download Error (Net::HTTP)")
      end
    end

    def store_in_active_storage
      Rails.logger.info("[#{File.basename(__FILE__)}] Storing boleto in ActiveStorage: #{@local_temp_path}")
      begin
        # Ensure file exists before trying to open it for ActiveStorage
        unless File.exist?(@local_temp_path)
          Rails.logger.error("[#{File.basename(__FILE__)}] Local temp file not found for ActiveStorage upload: #{@local_temp_path}")
          raise "Local temporary boleto file not found for upload."
        end

        blob = ActiveStorage::Blob.create_and_upload!(
          io: File.open(@local_temp_path, "rb"), # Open in binary read mode
          filename: @unique_filename_with_ext,
          content_type: "application/pdf",
          identify: false
        )

        unless ENV["APP_HOST"]
          Rails.logger.warn("[#{File.basename(__FILE__)}] APP_HOST environment variable is not set. short_download_url may generate incorrect URLs.")
        end

        # Generate a short token for this blob
        token = ShortUrlService.generate_for_blob(blob)

        # Use the short URL helper
        Rails.application.routes.url_helpers.short_download_url(token, host: ENV["APP_HOST"])
      rescue StandardError => e
        Rails.logger.error("[#{File.basename(__FILE__)}] Failed to store boleto in ActiveStorage.")
        Rails.logger.error("Error Type: #{e.class}")
        Rails.logger.error("Message: #{e.message}")
        Rails.logger.error("Filename: #{@unique_filename_with_ext}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise StorageError, "Failed to store Santander boleto PDF in ActiveStorage: #{e.message}"
      end
    end

    def handle_download_error(error, type)
      log_details = {
        type: type,
        class: error.class.name,
        message: error.message,
        url: @download_url_from_bank
      }
      if error.is_a?(OpenURI::HTTPError) && error.io.respond_to?(:status) # Should not happen if using Net::HTTP
        log_details[:http_status] = error.io.status.join(" ")
        log_details[:response_sample] = error.io.read(1024) if error.io.respond_to?(:read)
      end

      Rails.logger.error("[#{File.basename(__FILE__)}] Failed to download boleto.")
      log_details.each { |key, value| Rails.logger.error("#{key.to_s.capitalize}: #{value}") }
      # Log full backtrace for unexpected errors or if NET_HTTP_DEBUG_DOWNLOAD is set
      if ENV["NET_HTTP_DEBUG_DOWNLOAD"] == "true" || ![ "Timeout (Net::HTTP)", "SSL Error (Net::HTTP)", "Socket Error (Net::HTTP)", "System Call Error (Net::HTTP)" ].include?(type)
        Rails.logger.error(error.backtrace.join("\n"))
      end

      raise StorageError, "Error during Santander boleto PDF download (#{type}): #{error.message}"
    end
  end
end
