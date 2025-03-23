class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :asaas_customer_id, null: false, index: { unique: true }
      t.date :date_created
      t.string :name, null: false
      t.string :email
      t.string :company
      t.string :phone
      t.string :mobile_phone
      t.string :address
      t.string :address_number
      t.string :complement
      t.string :province
      t.string :postal_code
      t.string :cpf_cnpj, null: false
      t.string :person_type
      t.boolean :deleted, default: false
      t.text :additional_emails
      t.string :external_reference
      t.boolean :notification_disabled, default: false
      t.text :observations
      t.string :municipal_inscription
      t.string :state_inscription
      t.boolean :can_delete, default: true
      t.text :cannot_be_deleted_reason
      t.boolean :can_edit, default: true
      t.text :cannot_edit_reason
      t.integer :city_id
      t.string :city_name
      t.string :state
      t.string :country

      t.timestamps
    end

    add_index :customers, :cpf_cnpj, unique: true
    add_index :customers, :external_reference
  end
end
