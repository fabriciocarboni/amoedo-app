# app/controllers/api/v1/santander_cobrancas_controller.rb
module Api
  module V1
    class SantanderCobrancasController < BaseController
      def listar_cobrancas_cliente
        begin
          # Get cpf_cnpj directly from params
          cpf_cnpj = params[:cpf_cnpj]
          vencimento = params[:vencimento] # Novo parâmetro opcional

          if cpf_cnpj.blank?
            render json: { error: "CPF/CNPJ é obrigatório" }, status: :unprocessable_entity
            return
          end

          # Validação do formato do vencimento (MMYY)
          if vencimento.present? && !vencimento_valido?(vencimento)
            render json: { error: "Formato de vencimento inválido. Use o formato MMYY (ex: 0523 para maio de 2023)" },
                   status: :unprocessable_entity
            return
          end

          # Passa o parâmetro vencimento para o serviço
          result = Api::Santander::FetchCobrancaService.get_cobrancas(cpf_cnpj, vencimento)

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

      private

      # Método para validar o formato MMYY do vencimento
      def vencimento_valido?(vencimento)
        # Verifica se tem exatamente 4 dígitos
        return false unless vencimento.match?(/^\d{4}$/)

        # Extrai mês e ano
        mes = vencimento[0..1].to_i

        # Valida o mês (01-12)
        return false unless mes >= 1 && mes <= 12

        # Se chegou até aqui, o formato é válido
        true
      end
    end
  end
end
