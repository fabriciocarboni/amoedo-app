# app/controllers/remessa_uploads_controller.rb
class RemessaUploadsController < ApplicationController
  def new
    # This action will render the shared view with both Santander and Bradesco forms
  end

  def create
    result = case params[:bank]
    when "santander"
      result = Santander::RemessaUploadService.call(params[:remessa_file_santander])
    when "bradesco"
                # result = Bradesco::RemessaUploadService.call(params[:remessa_file_bradesco])
               { success: false, error: "Bradesco upload not implemented yet" }
    else
               { success: false, error: "Invalid bank selected" }
    end

    if result[:success]
      redirect_to new_remessa_upload_path, notice: "Arquivo de remessa #{params[:bank].capitalize} processado com sucesso."
    else
      redirect_to new_remessa_upload_path, alert: "Erro ao processar arquivo: #{result[:error]}"
    end
  end
end
