# app/controllers/api/v1/santander_cobrancas_controller.rb
module Api
  module V1
    class SantanderCobrancasController < BaseController
      def listar_cobrancas_cliente
        begin
          cpf_cnpj = params[:cpf_cnpj]
          nosso_numero = params[:nosso_numero] # New required parameter

          if cpf_cnpj.blank?
            render json: { error: "CPF/CNPJ é obrigatório" }, status: :unprocessable_entity
            return
          end

          if nosso_numero.blank?
            render json: { error: "Nosso número é obrigatório" }, status: :unprocessable_entity
            return
          end

          # Process single boleto with bank API call
          result = Api::Santander::FetchCobrancaService.get_single_cobranca(cpf_cnpj, nosso_numero)

          render json: result, status: :ok
        rescue ActiveRecord::RecordNotFound => e
          render json: { status: "client_noslips", msg: "Boleto não encontrado" }, status: :not_found
        rescue StandardError => e
          Rails.logger.error("Erro ao listar_cobrancas_cliente: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))

          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
