class CreateCobrancas < ActiveRecord::Migration[8.0]
  def change
    create_table :cobrancas do |t|
      # Basic Payment Information
      t.string :asaas_payment_id, index: { unique: true }
      t.string :asaas_customer_id, index: { unique: false }
      t.date :date_created, index: { unique: false }
      t.string :status, index: { unique: false }
      t.references :remessa, foreign_key: { to_table: :remessa_santander_registros }, index: { unique: false }, null: false
      t.integer :nome_banco

      # Financial Details
      t.decimal :value, precision: 10, scale: 2
      t.decimal :net_value, precision: 10, scale: 2
      t.decimal :original_value, precision: 10, scale: 2

      # Remove duplicate interest_value field
      t.decimal :interest_value, precision: 10, scale: 2

      # Payment Schedule
      t.date :due_date, index: { unique: false }
      t.date :original_due_date
      t.date :payment_date, index: { unique: false }
      t.date :client_payment_date, index: { unique: false }
      t.date :credit_date
      t.date :estimated_credit_date

      # Payment Method
      t.string :billing_type, index: { unique: false }
      t.boolean :can_be_paid_after_due_date
      t.string :pix_transaction

      # Description and References
      t.text :description
      t.string :external_reference
      t.integer :installment_number

      # Document Information
      t.string :invoice_url
      t.string :bank_slip_url
      t.string :invoice_number, index: { unique: false }
      t.string :nosso_numero, index: { unique: false }

      # Additional Fees
      t.decimal :discount_value, precision: 10, scale: 2
      t.date :discount_limit_date
      t.integer :discount_due_date_limit_days
      t.string :discount_type

      t.decimal :fine_value, precision: 10, scale: 2
      t.string :fine_type

      t.string :interest_type

      # Add reference to customer
      t.references :customer, foreign_key: true, index: true

      t.timestamps
    end
  end
end
