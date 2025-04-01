class AllowNullForAsaasCustomerId < ActiveRecord::Migration[8.0]
  def up
    change_column_null :customers, :asaas_customer_id, true
  end

  def down
    change_column_null :customers, :asaas_customer_id, false
  end
end
