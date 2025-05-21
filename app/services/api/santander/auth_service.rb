# app/services/api/santander/auth_service.rb
module Api
  module Santander
    class AuthService
      require "net/http"
      require "openssl"
      require "uri"
      require "json" # For parsing the response

      def self.fetch_token(subsidiary_key)
        credentials = HttpClientHelper.client_credentials_for(subsidiary_key)
        HttpClientHelper.log_credentials_status(subsidiary_key, credentials)

        auth_url_string = "#{HttpClientHelper.base_uri}/auth/oauth/v2/token"
        Rails.logger.info("\n[#{File.basename(__FILE__)}] Requesting auth token from: #{auth_url_string} for subsidiary: #{subsidiary_key} using Net::HTTP\n")

        uri = URI.parse(auth_url_string)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        # Create and configure SSLContext (can still use part of HttpClientHelper logic)
        # We need the p12 object to get cert and key
        begin
          p12 = OpenSSL::PKCS12.new(File.read(credentials[:pfx_path]), credentials[:pfx_password])
          http.cert = p12.certificate
          http.key = p12.key
        rescue OpenSSL::PKCS12::PKCS12Error => e
          Rails.logger.error("[#{File.basename(__FILE__)}] Failed to load PKCS12 certificate for Net::HTTP: #{e.message}")
          raise "Failed to load PKCS12 certificate for #{subsidiary_key}: #{e.message}"
        end

        # Configure server certificate verification (important for production)
        # Using VERIFY_NONE for now to match previous state, but this should be reviewed.
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: Change to VERIFY_PEER and set ca_file/ca_path
        # if http.verify_mode == OpenSSL::SSL::VERIFY_PEER
        #   http.ca_file = Rails.root.join('config', 'certificates', 'server_ca_bundle.pem').to_s # Example
        # end

        # Set TLS version if necessary (Net::HTTP usually negotiates well)
        # http.min_version = :TLS1_2 # or OpenSSL::SSL::TLS1_2_VERSION

        # Enable debug output for Net::HTTP if needed during further testing
        http.set_debug_output($stdout) if ENV["NET_HTTP_DEBUG"] == "true" || false # Control with ENV var or set to true

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({
          "client_id" => credentials[:client_id],
          "client_secret" => credentials[:client_secret],
          "grant_type" => "client_credentials"
        })
        request["Content-Type"] = "application/x-www-form-urlencoded"
        # Net::HTTP adds some default headers like Accept Encoding, User-Agent etc.

        begin
          Rails.logger.info("[#{File.basename(__FILE__)}] Sending Net::HTTP POST request to #{uri.host}#{uri.path}")
          response = http.request(request)

          Rails.logger.info("[#{File.basename(__FILE__)}] Net::HTTP Auth response code: #{response.code}")
          # Rails.logger.debug("[#{File.basename(__FILE__)}] Net::HTTP Auth response body: #{response.body}")

          unless response.is_a?(Net::HTTPSuccess) # Checks for 2xx status codes
            error_message = "Failed to get Santander authentication token (Net::HTTP): #{response.code} - #{response.message}. Body: #{response.body}"
            Rails.logger.error("[#{File.basename(__FILE__)}] #{error_message}")
            # Log response headers for debugging non-success cases
            response.each_header { |k, v| Rails.logger.error("[#{File.basename(__FILE__)}] Response Header: #{k}: #{v}") }
            raise StandardError, error_message
          end

          parsed_response = JSON.parse(response.body)
          token = parsed_response["access_token"]

          unless token
              error_message = "Santander authentication token not found in Net::HTTP response. Body: #{response.body}"
              Rails.logger.error("[#{File.basename(__FILE__)}] #{error_message}")
              raise StandardError, error_message
          end
          token

        rescue JSON::ParserError => e
          error_message = "Failed to parse Santander authentication response (Net::HTTP). Body: #{response&.body}. Error: #{e.message}"
          Rails.logger.error("[#{File.basename(__FILE__)}] #{error_message}")
          raise StandardError, error_message
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
          # More specific network/SSL error handling
          Rails.logger.error("[#{File.basename(__FILE__)}] Net::HTTP/SSL communication error in fetch_token for #{subsidiary_key}: #{e.class} - #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          raise # Re-raise as a more generic error or a custom one
        rescue StandardError => e
          Rails.logger.error("[#{File.basename(__FILE__)}] General error in fetch_token (Net::HTTP) for #{subsidiary_key}: #{e.message}")
          # Avoid logging e.backtrace.join("\n") for errors we've already specificially rescued unless more detail is needed
          raise # Re-raise
        ensure
            http.finish if http.started? # Ensure connection is closed
        end
      end
    end
  end
end
