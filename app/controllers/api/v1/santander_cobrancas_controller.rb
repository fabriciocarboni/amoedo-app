# app/controllers/api/v1/santander_cobrancas_controller.rb
module Api
  module V1
    class SantanderCobrancasController < BaseController
      def listar_cobrancas_cliente
        begin
          # Get cpf_cnpj directly from params
          cpf_cnpj = params[:cpf_cnpj]

          if cpf_cnpj.blank?
            render json: { error: "CPF/CNPJ é obrigatório" }, status: :unprocessable_entity
            return
          end

          result = Api::Santander::FetchCobrancaService.get_cobrancas(cpf_cnpj)

          render json: result, status: :ok
        rescue ActiveRecord::RecordNotFound => e
          render json: { status: "client_noslips", msg: "Cliente não encontrado com o CPF/CNPJ informado" }, status: :not_found
        rescue StandardError => e
          # Add logging to help diagnose the issue
          Rails.logger.error("Erro ao listar_cobrancas_cliente: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))

          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
