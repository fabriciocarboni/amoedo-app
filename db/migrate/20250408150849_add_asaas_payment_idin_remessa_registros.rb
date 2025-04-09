class AddAsaasPaymentIdinRemessaRegistros < ActiveRecord::Migration[8.0]
  def change
    add_column :remessa_santander_registros, :asaas_payment_id, :string
    add_index :remessa_santander_registros, :asaas_payment_id
  end
end
