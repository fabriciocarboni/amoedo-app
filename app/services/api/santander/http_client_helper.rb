# app/services/api/santander/http_client_helper.rb
module Api
  module Santander
    module HttpClientHelper
      extend self # Make module methods callable directly like HttpClientHelper.method_name

      # Mapping of CNPJ to subsidiary name (used for ENV var construction)
      # This could also live in FetchCobrancaService if it's the only one determining it initially.
      # For now, let's keep it here if Auth service might also need to derive subsidiary.
      SUBSIDIARY_MAPPING = {
        "55676560000152" => "SERGIPE",
        "21488450000103" => "BAHIA"
        # Add more subsidiaries as needed
      }.freeze

      # Determines the subsidiary string based on CNPJ for ENV var lookup.
      # Returns "SERGIPE" as a default if not found, with a warning.
      def determine_subsidiary_key(inscricao_beneficiario)
        subsidiary = SUBSIDIARY_MAPPING[inscricao_beneficiario]
        unless subsidiary
          Rails.logger.warn("[#{File.basename(__FILE__)}] Unknown beneficiary inscription: #{inscricao_beneficiario}. Defaulting to SERGIPE.")
          return "SERGIPE" # Default subsidiary key
        end
        subsidiary
      end

      def base_uri
        ENV["SANTANDER_BASE_URI"] || raise("SANTANDER_BASE_URI not set")
      end

      def client_credentials_for(subsidiary_key)
        client_id = ENV["SANTANDER_#{subsidiary_key.upcase}_CLIENT_ID"]
        client_secret = ENV["SANTANDER_#{subsidiary_key.upcase}_CLIENT_SECRET"]
        pfx_path_env = "SANTANDER_#{subsidiary_key.upcase}_CERT_PATH"
        pfx_path_val = ENV[pfx_path_env] || Rails.root.join("config", "certificates", "santander_#{subsidiary_key.downcase}.pfx").to_s
        pfx_password = ENV["SANTANDER_#{subsidiary_key.upcase}_CERT_PASSPHRASE"]

        unless client_id && client_secret && pfx_password
          error_message = "Missing Santander credentials for subsidiary #{subsidiary_key}: "
          error_message += "CLIENT_ID missing. " unless client_id
          error_message += "CLIENT_SECRET missing. " unless client_secret
          error_message += "CERT_PASSPHRASE missing. " unless pfx_password
          Rails.logger.error("[#{File.basename(__FILE__)}] #{error_message}")
          raise ArgumentError, error_message
        end

        unless File.exist?(pfx_path_val)
          Rails.logger.error("[#{File.basename(__FILE__)}] Certificate file not found: #{pfx_path_val} (derived from ENV['#{pfx_path_env}'] or default path)")
          raise "Certificate file not found for subsidiary: #{subsidiary_key} at #{pfx_path_val}"
        end

        {
          client_id: client_id,
          client_secret: client_secret,
          pfx_path: pfx_path_val,
          pfx_password: pfx_password
        }
      end

      def create_ssl_context(subsidiary_key)
        credentials = client_credentials_for(subsidiary_key)
        pfx_path = credentials[:pfx_path]
        pfx_password = credentials[:pfx_password]

        ssl_context = OpenSSL::SSL::SSLContext.new
        begin
          p12 = OpenSSL::PKCS12.new(File.read(pfx_path), pfx_password)
          ssl_context.cert = p12.certificate # This is the client's certificate
          ssl_context.key = p12.key         # This is the client's private key

        rescue OpenSSL::PKCS12::PKCS12Error => e
          Rails.logger.error("[#{File.basename(__FILE__)}] Failed to load PKCS12 certificate for #{subsidiary_key}: #{e.message}. Check PFX file and password.")
          raise "Failed to load PKCS12 certificate for #{subsidiary_key}: #{e.message}"
        end

        # ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: Change to VERIFY_PEER and add server CA if needed
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER # TODO: Change to VERIFY_PEER and add server CA if needed

        ssl_context.min_version = :TLS1_2 # Or OpenSSL::SSL::TLS1_2_VERSION


        Rails.logger.info("[#{File.basename(__FILE__)}] SSLContext created for #{subsidiary_key}. Cert CN: #{ssl_context.cert.subject.to_s if ssl_context.cert}")

        ssl_context
      end

      def log_credentials_status(subsidiary_key, credentials)
        Rails.logger.info("[#{File.basename(__FILE__)}] SANTANDER_BASE_URI: #{base_uri}")
        Rails.logger.info("[#{File.basename(__FILE__)}] SANTANDER_#{subsidiary_key.upcase}_CLIENT_ID: #{credentials[:client_id] ? 'Present (length: ' + credentials[:client_id].length.to_s + ')' : 'Missing'}")
        Rails.logger.info("[#{File.basename(__FILE__)}] SANTANDER_#{subsidiary_key.upcase}_CLIENT_SECRET: #{credentials[:client_secret] ? 'Present (length: ' + credentials[:client_secret].length.to_s + ')' : 'Missing'}")
        Rails.logger.info("[#{File.basename(__FILE__)}] SANTANDER_#{subsidiary_key.upcase}_CERT_PATH: #{credentials[:pfx_path]}")
        Rails.logger.info("[#{File.basename(__FILE__)}] SANTANDER_#{subsidiary_key.upcase}_CERT_PASSPHRASE: #{credentials[:pfx_password] ? 'Present' : 'Missing'}")
      end
    end
  end
end
