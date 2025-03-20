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

      file = params[:remessa_file_santander].tempfile
      result = Santander::RemessaProcessorService.new(file.path).process

      if result[:success]
        redirect_to new_santander_remessa_upload_path, notice: "Arquivo de remessa Santander processado com sucesso."
      else
        redirect_to new_santander_remessa_upload_path, alert: "Erro ao processar arquivo: #{result[:error]}"
      end
    end
  end
end
