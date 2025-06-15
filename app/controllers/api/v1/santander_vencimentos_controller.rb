# app/controllers/api/v1/santander_vencimentos_controller.rb
module Api
  module V1
    class SantanderVencimentosController < BaseController
      def listar_vencimentos
        begin
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          cpf_cnpj = params[:cpf_cnpj]
          vencimento = params[:vencimento]

          if cpf_cnpj.blank?
            render json: { error: "CPF/CNPJ é obrigatório" }, status: :unprocessable_entity
            return
          end

          # Validação do formato do vencimento (MMYY)
          if vencimento.present? && !vencimento_valido?(vencimento)
            render json: { error: "Formato de vencimento inválido. Use o formato MMYY (ex: 0625 para junho de 2025)" },
                   status: :unprocessable_entity
            return
          end

          result = Api::Santander::FetchVencimentosService.get_vencimentos(cpf_cnpj, vencimento)

          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = (end_time - start_time).round(2)

          # Update the tempo_de_execucao with actual calculated time
          result[:tempo_de_execucao] = "#{duration} seconds"

          render json: result, status: :ok

        rescue StandardError => e
          Rails.logger.error("Erro ao listar_vencimentos: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))

          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration = defined?(start_time) ? (end_time - start_time).round(2) : 0

          render json: {
            error: e.message,
            tempo_de_execucao: "#{duration} seconds"
          }, status: :internal_server_error
        end
      end

      private

      def vencimento_valido?(vencimento)
        return false unless vencimento.match?(/^\d{4}$/)
        mes = vencimento[0..1].to_i
        return false unless mes >= 1 && mes <= 12
        true
      end
    end
  end
end
