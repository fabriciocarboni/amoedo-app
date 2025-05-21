# app/controllers/api/v1/boletos_controller.rb
module Api
  module V1
    class BoletosController < BaseController
      def download
        filename = params[:filename].to_s

        # Prevent path traversal by rejecting filenames with directory traversal characters
        if filename.blank? || filename.include?("..") || filename.include?("/") || filename.include?("\\")
          return render json: { error: "Invalid filename" }, status: :bad_request
        end

        # Only allow certain file extensions (assuming PDFs)
        unless filename.downcase.end_with?(".pdf")
          return render json: { error: "Invalid file format" }, status: :bad_request
        end

        # Ensure filename only contains safe characters
        unless filename.match?(/\A[a-zA-Z0-9_\-\.]+\z/)
          return render json: { error: "Invalid filename format" }, status: :bad_request
        end

        file_path = File.join(Api::Santander::FetchCobrancaService::BOLETOS_DIR, filename)

        # Extra security: ensure the resolved path is still within the expected directory
        unless file_path.start_with?(Api::Santander::FetchCobrancaService::BOLETOS_DIR)
          return render json: { error: "Invalid file path" }, status: :bad_request
        end

        if File.exist?(file_path)
          send_file file_path, type: "application/pdf", disposition: "inline"
        else
          render json: { error: "Boleto not found" }, status: :not_found
        end
      end
    end
  end
end
