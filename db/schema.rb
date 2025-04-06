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

ActiveRecord::Schema[8.0].define(version: 2025_04_05_191300) do
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
    t.index ["processamento_id"], name: "index_remessa_santander_registros_on_processamento_id"
    t.index ["remessa_santander_header_id"], name: "idx_on_remessa_santander_header_id_4776cc7613"
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

  add_foreign_key "remessa_santander_registros", "remessa_santander_headers"
  add_foreign_key "sessions", "users"
end
