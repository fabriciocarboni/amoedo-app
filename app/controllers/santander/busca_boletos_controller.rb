module Santander
  class BuscaBoletosController < ApplicationController
    def create
      # Get form parameters
      cpf_cnpj = params[:cpf_cnpj]
      nosso_numero = params[:nosso_numero]

      # Validate inputs
      if cpf_cnpj.blank? && nosso_numero.blank?
        flash[:error] = "Por favor, preencha pelo menos um dos campos."
        redirect_to root_path and return
      end

      begin
        # Call the service
        service = FetchCobrancaService.new
        @cobrancas = service.fetch_cobranca(cpf_cnpj, nosso_numero)

        # Check if any results were found
        if @cobrancas.empty?
          flash[:warning] = "Nenhuma cobrança encontrada com os critérios informados."
          redirect_to root_path
        else
          render :result
        end
      rescue StandardError => e
        Rails.logger.error "Erro ao buscar cobranças: #{e.message}"
        flash[:error] = "Ocorreu um erro ao buscar as cobranças. Por favor, tente novamente."
        redirect_to root_path
      end
    end
  end
end
