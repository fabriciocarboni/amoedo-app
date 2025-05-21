# app/controllers/api/v1/boletos_controller.rb
module Api
  module V1
    class BoletosController < BaseController
      def download
        requested_filename = params[:filename].to_s

        # Get a list of actual files in the directory
        available_files = Dir.glob(File.join(Api::Santander::FetchCobrancaService::BOLETOS_DIR, "*.pdf"))
                            .map { |path| File.basename(path) }

        # Check if the requested filename exists in the directory
        if available_files.include?(requested_filename)
          file_path = File.join(Api::Santander::FetchCobrancaService::BOLETOS_DIR, requested_filename)
          send_file file_path, type: "application/pdf", disposition: "inline"
        else
          render json: { error: "Boleto not found" }, status: :not_found
        end
      end
    end
  end
end
