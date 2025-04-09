# app/services/asaas_customer_verification_service.rb
require "httparty"

class AsaasCustomerVerificationService
  include HTTParty
  base_uri ENV["ASAAS_BASE_URI"]

  def self.exists?(cpf_cnpj)
    response = get("/customers",
      query: { cpfCnpj: cpf_cnpj },
      headers: { "accept" => "application/json", "access_token" => ENV["ASAAS_TOKEN"] }
    )

    if response.success?
      data = JSON.parse(response.body)
      if !data["data"].empty?
        data["data"].first  # Return the first customer found
      else
        false
      end
    else
      Rails.logger.error "[#{File.basename(__FILE__)}] Asaas API error: #{response.code} - #{response.body}"
      false
    end
  end

  def self.get_asaas_id(cpf_cnpj)
    response = get("/customers",
      query: { cpfCnpj: cpf_cnpj },
      headers: {
        "accept" => "application/json",
        "access_token" => ENV["ASAAS_TOKEN"]
      }
    )

    if response.success?
      data = JSON.parse(response.body)
      data["data"].first["id"] if !data["data"].empty?
    else
      Rails.logger.error "[#{File.basename(__FILE__)}] Asaas API error: #{response.code} - #{response.body}"
      nil
    end
  end
end
