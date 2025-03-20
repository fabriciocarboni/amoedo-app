module Bradesco
  class RemessaUploadsController < ApplicationController
    def new
      # Render the form for Bradesco uploads
    end

    def create
      result = Bradesco::RemessaUploadService.call(params[:remessa_file_bradesco])

      if result[:success]
        redirect_to new_bradesco_remessa_upload_path, notice: "Arquivo de remessa Bradesco processado com sucesso."
      else
        redirect_to new_bradesco_remessa_upload_path, alert: "Erro ao processar arquivo: #{result[:error]}"
      end
    end
  end
end
