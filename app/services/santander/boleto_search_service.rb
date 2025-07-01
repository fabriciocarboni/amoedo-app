# app/services/santander/boleto_search_service.rb
module Santander
  class BoletoSearchService
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :cpf_cnpj, :string
    attribute :vencimento, :string

    validates :cpf_cnpj, presence: true
    validate :validate_cpf_cnpj_format
    validate :validate_vencimento_format, if: -> { vencimento.present? }

    def initialize(params = {})
      super
      # Fix: Clean CPF/CNPJ during initialization
      self.cpf_cnpj = clean_cpf_cnpj(self.cpf_cnpj) if self.cpf_cnpj.present?
      Rails.logger.info("[BoletoSearchService] Initialized with CPF/CNPJ: #{cpf_cnpj}, Vencimento: #{vencimento}")
    end

    def call
      Rails.logger.info("[BoletoSearchService] Validating...")

      unless valid?
        Rails.logger.error("[BoletoSearchService] Validation failed: #{errors.full_messages}")
        return failure_result("Parâmetros inválidos", errors.full_messages)
      end

      begin
        Rails.logger.info("[BoletoSearchService] Searching with CPF/CNPJ: #{cpf_cnpj}, Vencimento: #{vencimento}")

        boletos = search_boletos

        Rails.logger.info("[BoletoSearchService] Found #{boletos.count} boletos")

        if boletos.empty?
          return failure_result("Nenhum boleto encontrado", [ "Não foram encontrados boletos para os critérios informados" ])
        end

        success_result(format_boletos(boletos))
      rescue StandardError => e
        Rails.logger.error("[BoletoSearchService] Error: #{e.message}")
        Rails.logger.error("[BoletoSearchService] Backtrace: #{e.backtrace.first(5).join("\n")}")
        failure_result("Erro interno", [ "Ocorreu um erro ao buscar os boletos" ])
      end
    end

    private

    def search_boletos
      # Fix: Use the cleaned cpf_cnpj directly
      Rails.logger.info("[BoletoSearchService] Querying with numero_de_inscricao_do_pagador: #{cpf_cnpj}")

      query = RemessaSantanderRegistro.where(numero_de_inscricao_do_pagador: cpf_cnpj)

      if vencimento.present?
        # Convert MMYY to date range for the entire month
        month, year = parse_vencimento(vencimento)
        start_date = Date.new(2000 + year, month, 1)
        end_date = start_date.end_of_month

        # Convert dates to the format stored in database (DDMMYY)
        start_string = start_date.strftime("%d%m%y")
        end_string = end_date.strftime("%d%m%y")

        Rails.logger.info("[BoletoSearchService] Date range: #{start_string} to #{end_string}")
        query = query.where(data_de_vencimento_do_boleto: start_string..end_string)
      else
        # If no vencimento provided, search current month
        current_month_start = Date.current.beginning_of_month
        current_month_end = Date.current.end_of_month

        start_string = current_month_start.strftime("%d%m%y")
        end_string = current_month_end.strftime("%d%m%y")

        Rails.logger.info("[BoletoSearchService] Current month range: #{start_string} to #{end_string}")
        query = query.where(data_de_vencimento_do_boleto: start_string..end_string)
      end

      query.order(:data_de_vencimento_do_boleto)
    end

    def format_boletos(boletos)
      boletos.map do |boleto|
        {
          id: boleto.id,
          nome_pagador: boleto.nome_do_pagador,
          cpf_cnpj: format_cpf_cnpj_for_display(cpf_cnpj),
          vencimento: format_vencimento_date(boleto.data_de_vencimento_do_boleto),
          valor: format_currency(boleto.valor_nominal_do_boleto),
          nosso_numero: boleto.identificacao_do_boleto_no_banco,
          numero_documento: boleto.numero_do_documento,
          endereco: format_endereco(boleto)
        }
      end
    end

    def clean_cpf_cnpj(cpf_cnpj)
      return nil if cpf_cnpj.blank?
      cleaned = cpf_cnpj.to_s.gsub(/[^\d]/, "")
      Rails.logger.info("[BoletoSearchService] Cleaned CPF/CNPJ: '#{cpf_cnpj}' -> '#{cleaned}'")
      cleaned
    end

    def validate_cpf_cnpj_format
      Rails.logger.info("[BoletoSearchService] Validating CPF/CNPJ: #{cpf_cnpj} (length: #{cpf_cnpj&.length})")

      return if cpf_cnpj.blank?

      unless cpf_cnpj.length.in?([ 11, 14 ])
        errors.add(:cpf_cnpj, "deve ter 11 dígitos (CPF) ou 14 dígitos (CNPJ). Atual: #{cpf_cnpj.length} dígitos")
      end
    end

    def validate_vencimento_format
      return if vencimento.blank?

      unless vencimento.match?(/\A\d{4}\z/)
        errors.add(:vencimento, "deve estar no formato MMAA (ex: 0325)")
        return
      end

      month, year = parse_vencimento(vencimento)

      unless month.between?(1, 12)
        errors.add(:vencimento, "mês deve estar entre 01 e 12")
      end
    end

    def parse_vencimento(vencimento_string)
      month = vencimento_string[0, 2].to_i
      year = vencimento_string[2, 2].to_i
      [ month, year ]
    end

    def format_vencimento_date(date_string)
      Date.strptime(date_string, "%d%m%y").strftime("%d/%m/%Y")
    rescue ArgumentError
      date_string # Return original if parsing fails
    end

    def format_currency(value)
      ActionController::Base.helpers.number_to_currency(
        value,
        unit: "R$",
        separator: ",",
        delimiter: "."
      )
    end

    def format_cpf_cnpj_for_display(cleaned_cpf_cnpj)
      return cleaned_cpf_cnpj if cleaned_cpf_cnpj.blank?

      if cleaned_cpf_cnpj.length == 11
        cleaned_cpf_cnpj.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
      elsif cleaned_cpf_cnpj.length == 14
        cleaned_cpf_cnpj.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5')
      else
        cleaned_cpf_cnpj
      end
    end

    def format_endereco(boleto)
      endereco_parts = [
        boleto.endereco_do_pagador,
        boleto.bairro_do_pagador,
        "#{boleto.cep_do_pagador}#{boleto.sufixo_do_cep_do_pagador}".presence,
        boleto.cidade_do_pagador,
        boleto.unidade_de_federacao_do_pagador
      ].compact.reject(&:blank?)

      endereco_parts.join(", ")
    end

    def success_result(data)
      {
        status: :success,
        data: data,
        count: data.length
      }
    end

    def failure_result(message, details = [])
      {
        status: :error,
        message: message,
        details: details
      }
    end
  end
end
