# app/controllers/santander/remessa_uploads_controller.rb
module Santander
  class RemessaUploadsController < ApplicationController
    def new
      # Render the form for Santander uploads
    end

    def create
      if params[:remessa_file_santander].nil?
        redirect_to new_santander_remessa_upload_path, alert: "Por favor, selecione um arquivo para upload."
        return
      end

      uploaded_file = params[:remessa_file_santander]
      file_path = uploaded_file.tempfile.path
      original_filename = uploaded_file.original_filename

      result = Santander::RemessaProcessorService.new(file_path, original_filename).process

      if result[:success]
        flash[:notice] = "Arquivo de remessa Santander processado com sucesso!"
        redirect_to new_santander_remessa_upload_path
      else
        flash[:alert] = "Erro ao processar arquivo: #{result[:error]}"
        redirect_to new_santander_remessa_upload_path
      end
    end
  end
end
