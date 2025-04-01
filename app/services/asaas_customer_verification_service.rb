# app/services/asaas_customer_verification_service.rb
require "httparty"

class AsaasCustomerVerificationService
  include HTTParty
  base_uri ENV["ASAAS_BASE_URI"]

  def self.exists?(identifier)
    response = get("/customers",
      query: identifier.include?("@") ? { email: identifier } : { cpfCnpj: identifier },
      headers: {
        "accept" => "application/json",
        "access_token" => ENV["ASAAS_TOKEN"]
      }
    )

    if response.success?
      data = JSON.parse(response.body)
      !data["data"].empty?
    else
      Rails.logger.error "\n[asaas_customer_verification_service.rb] Asaas API error: #{response.code} - #{response.body}\n"
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
      Rails.logger.error "\n[asaas_customer_verification_service.rb] Asaas API error: #{response.code} - #{response.body}\n"
      nil
    end
  end


  def self.get_customer(asaas_id)
    response = get("/customers/#{asaas_id}",
      headers: {
        "accept" => "application/json",
        "access_token" => ENV["ASAAS_TOKEN"]
      }
    )

    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error "\n[asaas_customer_verification_service.rb] Asaas API error: #{response.code} - #{response.body}\n"
      nil
    end
  end
end
