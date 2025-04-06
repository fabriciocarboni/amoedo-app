# app/services/asaas_customer_creation_service.rb
require "httparty"

class AsaasCobrancaCreationService
  include HTTParty
  base_uri ENV["ASAAS_BASE_URI"]

  def self.create(cobranca)
    response = post("/payments",
      body: { customer: asaas_customer_id
              name: name,
              cpfCnpj: cpf_cnpj }.to_json,
      headers: {
        "accept" => "application/json",
        "content-type" => "application/json",
        "access_token" => ENV["ASAAS_TOKEN"]
      }
    )

    if response.success?
      data = JSON.parse(response.body)
      { success: true, asaas_customer_id: data["id"] }
    else
      Rails.logger.error "\n[asaas_customer_creation_service.rb] Asaas API error: #{response.code} - #{response.body}\n"
      { success: false, error: "\n[asaas_customer_creation_service.rb] Failed to create customer in Asaas\n" }
    end
  end
end
