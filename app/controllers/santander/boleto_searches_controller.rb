# app/controllers/santander/boleto_searches_controller.rb
module Santander
  class BoletoSearchesController < ApplicationController
    def create
      Rails.logger.info("[BoletoSearchesController] Received params: #{search_params}")

      @search_service = ::Santander::BoletoSearchService.new(search_params)
      @result = @search_service.call

      Rails.logger.info("[BoletoSearchesController] Service result: #{@result[:status]} - #{@result[:message]}")

      if @result[:status] == :success
        @boletos = @result[:data]
        render :results
      else
        @search_params = search_params
        render :no_results
      end
    end

    private

    def search_params
      params.permit(:cpf_cnpj, :vencimento)
    end
  end
end
