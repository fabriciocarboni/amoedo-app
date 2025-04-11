# app/services/api/fetch_cobranca_service.rb
module Api
  class FetchCobrancaService
    def self.get_cobrancas(cpf_cnpj)
      if cpf_cnpj.blank?
        raise ArgumentError, "CPF/CNPJ cannot be blank"
      end

      customer = Customer.find_by(cpf_cnpj: cpf_cnpj)

      unless customer
        # Return a hash rather than raising an error
        return { status: "customer_notfound", msg: "Customer not found with provided CPF/CNPJ" }
      end

      unless customer.asaas_customer_id.present?
        return { status: "customer_noslips", data: [] }
      end

      pending_cobrancas = Cobranca.where(
        asaas_customer_id: customer.asaas_customer_id,
        status: "PENDING"
      )

      if pending_cobrancas.any?
        format_response_with_slips(pending_cobrancas)
      else
        recent_cobranca = Cobranca.where(asaas_customer_id: customer.asaas_customer_id)
                                  .order(created_at: :desc)
                                  .first

        if recent_cobranca
          format_response_without_slips(recent_cobranca)
        else
          { status: "customer_noslips", data: [] }
        end
      end
    end

      private

      def self.format_response_with_slips(cobrancas)
        {
          status: "customer_slips",
          data: cobrancas.map { |cobranca| format_cobranca_data(cobranca) }
        }
      end

      def self.format_response_without_slips(cobranca)
        {
          status: "customer_noslips",
          data: [ format_cobranca_data(cobranca) ]
        }
      end

      def self.format_cobranca_data(cobranca)
        {
          asaas_payment_id: cobranca.asaas_payment_id,
          asaas_customer_id: cobranca.asaas_customer_id,
          date_created: cobranca.due_date.is_a?(String) ? Date.strptime(cobranca.date_created, "%d%m%y").strftime("%d/%m/%Y") : cobranca.date_created.strftime("%d/%m/%Y"),
          due_date: cobranca.due_date.is_a?(String) ? Date.strptime(cobranca.due_date, "%d%m%y").strftime("%d/%m/%Y") : cobranca.due_date.strftime("%d/%m/%Y"),
          status: cobranca.status,
          value: cobranca.value,
          invoice_url: cobranca.invoice_url,
          bank_slip_url: cobranca.bank_slip_url
        }
      end
  end
end
