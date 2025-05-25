# app/controllers/santander/remessa_uploads_controller.rb
module Santander
  class RemessaUploadsController < ApplicationController
    def new
      # Render the form for Santander uploads
      @show_success_modal = flash[:show_success_modal]
      @nome_arquivo_remessa = flash[:nome_arquivo_remessa]
      @registros_count = flash[:registros_count]
      @valor_total_dos_boletos = flash[:valor_total_dos_boletos]
      @valor_total_mismatch = flash[:valor_total_mismatch]
      @soma_registros = flash[:soma_registros]
      @skip_registros = flash[:skip_registros]
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
        # Prepare data for the success modal
        processamento_id = result[:processamento_id]

        # Get the trailer record
        trailer = RemessaSantanderTrailer.find_by(processamento_id: processamento_id)

        # Get the registros
        registros = RemessaSantanderRegistro.where(processamento_id: processamento_id)

        # Calculate the sum of valor_nominal_do_boleto from registros
        soma_registros = registros.sum(:valor_nominal_do_boleto)

        # Check if the sum matches the valor_total_dos_boletos from trailer
        if trailer.present?
          valor_total_mismatch = (soma_registros.round(2) != trailer.valor_total_dos_boletos.round(2))
          flash[:valor_total_mismatch] = valor_total_mismatch
          flash[:valor_total_dos_boletos] = trailer.valor_total_dos_boletos
        end

        # Use flash.now for Turbo Stream responses
        flash[:show_success_modal] = true
        flash[:nome_arquivo_remessa] = original_filename
        flash[:registros_count] = registros.count
        flash[:soma_registros] = soma_registros if valor_total_mismatch
        # capture the skipped_registros value
        flash[:skip_registros] = result[:skipped_registros]

        # Add debug log
        Rails.logger.debug "Setting flash[:skip_registros] to #{result[:skipped_registros]}"
        Rails.logger.debug "result.inspect #{result.inspect}"
        redirect_to new_santander_remessa_upload_path
      else
        flash[:alert] = "Erro ao processar arquivo: #{result[:error]}"
        redirect_to new_santander_remessa_upload_path
      end
    end
  end
end
