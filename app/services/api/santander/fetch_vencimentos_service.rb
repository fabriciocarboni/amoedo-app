# app/services/api/santander/fetch_vencimentos_service.rb
module Api
  module Santander
    class FetchVencimentosService
      def self.get_vencimentos(cpf_cnpj_raw, vencimento = nil)
        if cpf_cnpj_raw.blank?
          raise ArgumentError, "CPF/CNPJ cannot be blank"
        end

        clean_cpfcnpj = clean_cpf_cnpj(cpf_cnpj_raw)

        # Use o vencimento informado ou o mês atual como padrão
        month_year = vencimento.present? ? vencimento : Time.current.strftime("%m%y")

        # Query apenas no banco de dados - SEM chamadas para API do banco
        clients = RemessaSantanderRegistro
          .where(numero_de_inscricao_do_pagador: clean_cpfcnpj)
          .where("SUBSTRING(data_de_vencimento_do_boleto, 3, 4) = ?", month_year)

        unless clients.exists?
          return {
            status: "customer_notfound",
            msg: "Cliente não encontrado com o CPF/CNPJ informado para o período especificado.",
            quantidade_boletos: "0",
            data: []
          }
        end

        vencimentos_list = []

        clients.each do |client_record|
          next unless client_record.identificacao_do_boleto_no_banco.present?

          begin
            raw_vencimento_string = client_record.data_de_vencimento_do_boleto
            parsed_vencimento_date = Date.strptime(raw_vencimento_string, "%d%m%y")
            formatted_vencimento = parsed_vencimento_date.strftime("%d/%m/%Y")

            formatted_valor = ActionController::Base.helpers.number_to_currency(
              client_record.valor_nominal_do_boleto,
              unit: "R$",
              separator: ",",
              delimiter: "."
            )

            vencimentos_list << {
              nome_client: client_record.nome_do_pagador,
              cpf_cnpj: format_cpf_cnpj_for_display(clean_cpfcnpj),
              vencimento: formatted_vencimento,
              valor: formatted_valor,
              nosso_numero: client_record.identificacao_do_boleto_no_banco
            }
          rescue ArgumentError => e
            Rails.logger.warn("Data de vencimento inválida para registro ID #{client_record.id}: #{e.message}")
            next
          end
        end

        if vencimentos_list.any?
          {
            status: "available_duedate",
            quantidade_boletos: vencimentos_list.size.to_s,
            tempo_de_execucao: "0.00 seconds", # will be updated by controller
            data: vencimentos_list
          }
        else
          {
            status: "customer_notfound",
            msg: "Nenhum boleto encontrado com dados válidos para o período especificado.",
            quantidade_boletos: "0",
            data: []
          }
        end
      end

      private

      def self.clean_cpf_cnpj(cpf_cnpj)
        cpf_cnpj.to_s.gsub(/[^\d]/, "")
      end

      def self.format_cpf_cnpj_for_display(cleaned_cpf_cnpj)
        return cleaned_cpf_cnpj if cleaned_cpf_cnpj.blank?
        if cleaned_cpf_cnpj.length == 11
          cleaned_cpf_cnpj.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
        elsif cleaned_cpf_cnpj.length == 14
          cleaned_cpf_cnpj.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5')
        else
          cleaned_cpf_cnpj
        end
      end
    end
  end
end
