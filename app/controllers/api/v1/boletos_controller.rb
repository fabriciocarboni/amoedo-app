# app/controllers/api/v1/boletos_controller.rb
module Api
  module V1
    class BoletosController < BaseController
      def download
        filename = params[:filename]
        file_path = File.join(Api::Santander::FetchCobrancaService::BOLETOS_DIR, filename)

        if File.exist?(file_path)
          send_file file_path, type: "application/pdf", disposition: "inline"
        else
          render json: { error: "Boleto not found" }, status: :not_found
        end
      end
    end
  end
end
