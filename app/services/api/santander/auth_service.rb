# app/services/api/santander/auth_service.rb
module Api
  module Santander
    class AuthService
      require "net/http"
      require "openssl"
      require "uri"
      require "json"

      # Default buffer in seconds to subtract from token's actual expiry
      # This helps avoid using a token that's just about to expire.
      TOKEN_EXPIRY_BUFFER = 60.seconds

      def self.fetch_token(subsidiary_key)
        cache_key = "santander/auth_token/#{subsidiary_key}"

        # 1. Try to read from cache
        cached_token_data = Rails.cache.read(cache_key)
        if cached_token_data.present? && cached_token_data[:token].present?
          Rails.logger.info("\n[#{File.basename(__FILE__)}] CACHE HIT: Found token for subsidiary '#{subsidiary_key}' in cache.")
          return cached_token_data[:token]
        end

        Rails.logger.info("\n[#{File.basename(__FILE__)}] CACHE MISS: No valid token for subsidiary '#{subsidiary_key}' in cache. Fetching new token.")

        # 2. If not in cache or expired, fetch a new token
        credentials = HttpClientHelper.client_credentials_for(subsidiary_key)
        HttpClientHelper.log_credentials_status(subsidiary_key, credentials) # Assumes this handles nil credentials

        auth_url_string = "#{HttpClientHelper.base_uri}/auth/oauth/v2/token"
        Rails.logger.info("\n[#{File.basename(__FILE__)}] Requesting new auth token from: #{auth_url_string} for subsidiary: #{subsidiary_key}")

        uri = URI.parse(auth_url_string)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        begin
          p12 = OpenSSL::PKCS12.new(File.read(credentials[:pfx_path]), credentials[:pfx_password])
          http.cert = p12.certificate
          http.key = p12.key
        rescue OpenSSL::PKCS12::PKCS12Error => e
          msg = "Failed to load PKCS12 certificate for Net::HTTP (subsidiary: #{subsidiary_key}): #{e.message}"
          Rails.logger.error("[#{File.basename(__FILE__)}] #{msg}")
          raise ArgumentError, msg # Propagate as ArgumentError for config issue
        rescue Errno::ENOENT => e
          msg = "PFX file not found at path '#{credentials[:pfx_path]}' for subsidiary #{subsidiary_key}: #{e.message}"
          Rails.logger.error("[#{File.basename(__FILE__)}] #{msg}")
          raise ArgumentError, msg # Propagate as ArgumentError for config issue
        end

        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.set_debug_output($stdout) if ENV["NET_HTTP_DEBUG"] == "true"

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({
          "client_id" => credentials[:client_id],
          "client_secret" => credentials[:client_secret],
          "grant_type" => "client_credentials"
        })
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request["Accept"] = "application/json" # Good practice

        response_body_for_error_logging = ""
        begin
          Rails.logger.info("[#{File.basename(__FILE__)}] Sending Net::HTTP POST request for token to #{uri.host}#{uri.path}")
          response = http.request(request)
          response_body_for_error_logging = response.body

          Rails.logger.info("[#{File.basename(__FILE__)}] Net::HTTP Auth response code: #{response.code}")

          unless response.is_a?(Net::HTTPSuccess)
            error_message = "Failed to get Santander authentication token (Net::HTTP): #{response.code} - #{response.message}. Body: #{response_body_for_error_logging}"
            Rails.logger.error("[#{File.basename(__FILE__)}] #{error_message}")
            response.each_header { |k, v| Rails.logger.error("[#{File.basename(__FILE__)}] Auth Response Header: #{k}: #{v}") }
            raise StandardError, error_message # Will be caught by specific network error or general StandardError below
          end

          parsed_response = JSON.parse(response.body)
          token = parsed_response["access_token"]
          expires_in_seconds = parsed_response["expires_in"] # e.g., 3600

          unless token.present?
            error_message = "Santander authentication token (access_token) not found in Net::HTTP response. Body: #{response.body}"
            Rails.logger.error("[#{File.basename(__FILE__)}] #{error_message}")
            raise StandardError, error_message
          end

          unless expires_in_seconds.is_a?(Integer) && expires_in_seconds > 0
            Rails.logger.warn("[#{File.basename(__FILE__)}] 'expires_in' missing or invalid in token response for subsidiary '#{subsidiary_key}'. Defaulting cache to 50 minutes. Body: #{response.body}")
            expires_in_seconds = 50 * 60 # Default to 50 minutes if not provided or invalid
          end

          # 3. Write the new token to cache
          # Subtract a buffer to ensure we refresh before actual expiry
          cache_duration = [ expires_in_seconds - TOKEN_EXPIRY_BUFFER, TOKEN_EXPIRY_BUFFER ].max.seconds # Ensure it's not negative

          token_data_to_cache = { token: token, expires_at: Time.current + expires_in_seconds.seconds }
          Rails.cache.write(cache_key, token_data_to_cache, expires_in: cache_duration)
          Rails.logger.info("\n[#{File.basename(__FILE__)}] CACHE WRITE: Stored new token for subsidiary '#{subsidiary_key}' in cache. Expires in: #{cache_duration / 60} minutes.")

          token # Return the newly fetched token

        rescue JSON::ParserError => e
          error_message = "Failed to parse Santander authentication response (Net::HTTP). Body: #{response_body_for_error_logging}. Error: #{e.message}"
          Rails.logger.error("[#{File.basename(__FILE__)}] #{error_message}")
          raise StandardError, error_message # Re-raise to be caught by FetchCobrancaService
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
          Rails.logger.error("[#{File.basename(__FILE__)}] Net::HTTP/SSL communication error in fetch_token for #{subsidiary_key}: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
          raise # Re-raise the original network/SSL error
        rescue StandardError => e
          # This will catch errors raised above like "Failed to get token" or "Token not found"
          Rails.logger.error("[#{File.basename(__FILE__)}] General error during new token fetch for subsidiary '#{subsidiary_key}': #{e.message}")
          raise # Re-raise the original error
        ensure
          http.finish if http && http.started?
        end
      end
    end
  end
end
