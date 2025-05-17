# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_15_105230) do
  create_table "api_keys", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "access_token", null: false
    t.string "client_name", null: false
    t.string "email", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_api_keys_on_access_token", unique: true
    t.index ["email"], name: "index_api_keys_on_email", unique: true
  end

  create_table "cobrancas", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "asaas_payment_id"
    t.string "asaas_customer_id"
    t.date "date_created"
    t.string "status"
    t.string "nome_banco"
    t.decimal "value", precision: 10, scale: 2
    t.decimal "net_value", precision: 10, scale: 2
    t.decimal "original_value", precision: 10, scale: 2
    t.decimal "interest_value", precision: 10, scale: 2
    t.date "due_date"
    t.date "original_due_date"
    t.date "payment_date"
    t.date "client_payment_date"
    t.date "credit_date"
    t.date "estimated_credit_date"
    t.string "billing_type"
    t.boolean "can_be_paid_after_due_date"
    t.string "pix_transaction"
    t.text "description"
    t.string "external_reference"
    t.integer "installment_number"
    t.string "invoice_url"
    t.string "bank_slip_url"
    t.string "invoice_number"
    t.string "nosso_numero"
    t.decimal "discount_value", precision: 10, scale: 2
    t.date "discount_limit_date"
    t.integer "discount_due_date_limit_days"
    t.string "discount_type"
    t.decimal "fine_value", precision: 10, scale: 2
    t.string "fine_type"
    t.string "interest_type"
    t.bigint "customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "processamento_id", null: false
    t.index ["asaas_customer_id"], name: "index_cobrancas_on_asaas_customer_id"
    t.index ["asaas_payment_id"], name: "index_cobrancas_on_asaas_payment_id", unique: true
    t.index ["billing_type"], name: "index_cobrancas_on_billing_type"
    t.index ["client_payment_date"], name: "index_cobrancas_on_client_payment_date"
    t.index ["customer_id"], name: "index_cobrancas_on_customer_id"
    t.index ["date_created"], name: "index_cobrancas_on_date_created"
    t.index ["due_date"], name: "index_cobrancas_on_due_date"
    t.index ["invoice_number"], name: "index_cobrancas_on_invoice_number"
    t.index ["nosso_numero"], name: "index_cobrancas_on_nosso_numero"
    t.index ["payment_date"], name: "index_cobrancas_on_payment_date"
    t.index ["processamento_id"], name: "index_cobrancas_on_processamento_id"
    t.index ["status"], name: "index_cobrancas_on_status"
  end

  create_table "customers", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "asaas_customer_id"
    t.date "date_created"
    t.string "name", null: false
    t.string "email"
    t.string "company"
    t.string "phone"
    t.string "mobile_phone"
    t.string "address"
    t.string "address_number"
    t.string "complement"
    t.string "province"
    t.string "postal_code"
    t.string "cpf_cnpj", null: false
    t.string "person_type"
    t.boolean "deleted", default: false
    t.text "additional_emails"
    t.string "external_reference"
    t.boolean "notification_disabled", default: false
    t.text "observations"
    t.string "municipal_inscription"
    t.string "state_inscription"
    t.boolean "can_delete", default: true
    t.text "cannot_be_deleted_reason"
    t.boolean "can_edit", default: true
    t.text "cannot_edit_reason"
    t.integer "city_id"
    t.string "city_name"
    t.string "state"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asaas_customer_id"], name: "index_customers_on_asaas_customer_id", unique: true
    t.index ["cpf_cnpj"], name: "index_customers_on_cpf_cnpj", unique: true
    t.index ["external_reference"], name: "index_customers_on_external_reference"
  end

  create_table "remessa_santander_headers", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "codigo_do_registro", limit: 1
    t.string "codigo_da_remessa", limit: 1
    t.string "literal_de_transmissao", limit: 7
    t.string "codigo_do_tipo_servico", limit: 2
    t.string "literal_de_servico", limit: 15
    t.string "codigo_de_transmissao", limit: 20
    t.string "nome_do_beneficiario", limit: 30
    t.string "codigo_do_banco", limit: 3
    t.string "nome_do_banco", limit: 15
    t.string "data_da_geracao_do_arquivo", limit: 6
    t.string "reservado_uso_banco_1", limit: 6
    t.string "mensagem_1", limit: 47
    t.string "mensagem_2", limit: 47
    t.string "mensagem_3", limit: 47
    t.string "mensagem_4", limit: 47
    t.string "mensagem_5", limit: 47
    t.string "reservado_uso_banco_2", limit: 34
    t.string "reservado_uso_banco_3", limit: 6
    t.string "numero_sequencial_do_arquivo", limit: 3
    t.string "numero_sequencial_do_registro_no_arquivo", limit: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nome_arquivo_remessa", null: false
    t.integer "processamento_id", null: false
    t.index ["processamento_id"], name: "index_remessa_santander_headers_on_processamento_id"
  end

  create_table "remessa_santander_registros", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "remessa_santander_header_id"
    t.string "codigo_do_registro", limit: 1
    t.string "tipo_de_inscricao_do_beneficiario", limit: 2
    t.string "numero_de_inscricao_do_beneficiario", limit: 14
    t.string "codigo_da_agencia_beneficiario", limit: 4
    t.string "conta_movimento_beneficiario", limit: 8
    t.string "conta_cobranca_beneficiario", limit: 8
    t.string "identificacao_do_boleto_na_empresa", limit: 25
    t.string "identificacao_do_boleto_no_banco", limit: 8
    t.string "data_do_desconto_2", limit: 6
    t.string "reservado_uso_banco_1", limit: 1
    t.string "codigo_de_multa", limit: 1
    t.decimal "percentual_de_multa", precision: 4, scale: 2
    t.string "codigo_da_moeda", limit: 2
    t.decimal "valor_do_boleto_em_outra_unidade", precision: 10, scale: 2
    t.string "reservado_uso_banco_2", limit: 4
    t.string "data_da_multa", limit: 6
    t.string "tipo_de_cobranca", limit: 1
    t.string "codigo_de_movimento_remessa", limit: 2
    t.string "numero_do_documento", limit: 10
    t.string "data_de_vencimento_do_boleto", limit: 6
    t.decimal "valor_nominal_do_boleto", precision: 13, scale: 2
    t.string "numero_do_banco_cobrador", limit: 3
    t.string "codigo_agencia_cobradora", limit: 5
    t.string "especie_do_boleto", limit: 2
    t.string "identificacao_boleto_aceite_nao_aceite", limit: 1
    t.string "data_de_emissao_do_boleto", limit: 6
    t.string "primeira_instrucao", limit: 2
    t.string "segunda_instrucao", limit: 2
    t.decimal "valor_de_mora_dia", precision: 13, scale: 2
    t.string "data_limite_para_concessao_do_desconto", limit: 6
    t.decimal "valor_do_desconto_a_ser_concedido", precision: 13, scale: 2
    t.decimal "percentual_do_iof_a_ser_recolhido", precision: 13, scale: 5
    t.decimal "valor_do_abatimento_ou_valor_do_segundo_desconto", precision: 13, scale: 2
    t.string "tipo_de_inscricao_do_pagador", limit: 2
    t.string "numero_de_inscricao_do_pagador", limit: 14
    t.string "nome_do_pagador", limit: 40
    t.string "endereco_do_pagador", limit: 40
    t.string "bairro_do_pagador", limit: 12
    t.string "cep_do_pagador", limit: 5
    t.string "sufixo_do_cep_do_pagador", limit: 3
    t.string "cidade_do_pagador", limit: 15
    t.string "unidade_de_federacao_do_pagador", limit: 2
    t.string "reservado_uso_banco_3", limit: 30
    t.string "reservado_uso_banco_4", limit: 1
    t.string "identificador_do_complemento", limit: 2
    t.string "complemento", limit: 2
    t.string "reservado_uso_banco_5", limit: 6
    t.string "numero_de_dias_corridos_para_protesto", limit: 2
    t.string "reservado_uso_banco_6", limit: 1
    t.string "numero_sequencial_do_registro_no_arquivo", limit: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nome_arquivo_remessa", null: false
    t.integer "processamento_id", null: false
    t.string "asaas_payment_id"
    t.index ["asaas_payment_id"], name: "index_remessa_santander_registros_on_asaas_payment_id"
    t.index ["identificacao_do_boleto_na_empresa"], name: "index_remessa_santander_registros_on_id_boleto"
    t.index ["processamento_id"], name: "index_remessa_santander_registros_on_processamento_id"
    t.index ["remessa_santander_header_id"], name: "idx_on_remessa_santander_header_id_4776cc7613"
  end

  create_table "remessa_santander_trailers", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "codigo_do_registro", limit: 1
    t.string "quantidade_de_registros_no_arquivo", limit: 6
    t.decimal "valor_total_dos_boletos", precision: 11, scale: 2
    t.string "numero_sequencial_de_registros_no_arquivo", limit: 6
    t.string "nome_arquivo_remessa", null: false
    t.integer "processamento_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["processamento_id"], name: "index_remessa_santander_trailers_on_processamento_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "cobrancas", "customers"
  add_foreign_key "remessa_santander_registros", "remessa_santander_headers"
  add_foreign_key "sessions", "users"
end
