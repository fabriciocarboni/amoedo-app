# app/services/asaas_customer_creation_service.rb
require "httparty"

class AsaasCustomerCreationService
  include HTTParty
  base_uri ENV["ASAAS_BASE_URI"]

  def self.create(cpf_cnpj, name)
    response = post("/customers",
      body: { name: name, cpfCnpj: cpf_cnpj }.to_json,
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
      Rails.logger.error "[#{File.basename(__FILE__)}] Asaas API error: #{response.code} - #{response.body}\n"
      { success: false, error: "Failed to create customer in Asaas\n" }
    end
  end
end
