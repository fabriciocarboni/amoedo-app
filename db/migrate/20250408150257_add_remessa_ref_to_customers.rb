class AddRemessaRefToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_reference :customers, :remessa, foreign_key: { to_table: :remessa_santander_registros }
  end
end
