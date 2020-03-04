class CreateFiInvoiceItems < ActiveRecord::Migration[6.0]
  def change
    create_table :fi_invoice_items do |t|
      t.string :token
      t.integer :invoice_id
      t.string :invoice_itemable_type
      t.integer :invoice_itemable_id
      t.decimal :sub_total, precision: 10, scale: 2
      t.text :description
      
      t.timestamps
    end
  end
end
