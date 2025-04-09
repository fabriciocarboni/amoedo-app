# app/services/asaas_cobranca_creation_service.rb
require "httparty"

class AsaasCobrancaCreationService
  include HTTParty
  base_uri ENV["ASAAS_BASE_URI"]


  def self.create(cobranca)
    response = post("/payments",
      body: {
        customer: cobranca[:asaas_customer_id],
        name: cobranca[:nome],
        value: cobranca[:value],
        dueDate: cobranca[:dueDate],
        billingType: cobranca[:billingType],
        description: cobranca[:description],
        fine: cobranca[:fine]
      }.to_json,
      headers: {
        "accept" => "application/json",
        "content-type" => "application/json",
        "access_token" => ENV["ASAAS_TOKEN"]
      }
    )

    if response.success?
      data = JSON.parse(response.body)
      { success: true, data: data }
    else
      Rails.logger.error "[#{File.basename(__FILE__)}] Asaas API error: #{response.code} - #{response.body}"
      { success: false, error: "Failed to create payment in Asaas" }
    end
  end
end
