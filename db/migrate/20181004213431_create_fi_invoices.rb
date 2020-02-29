class CreateFiInvoices < ActiveRecord::Migration[6.0]
  def change
    create_table :fi_invoices do |t|
      t.string :token
      t.string :invoiceable_type
      t.integer :invoiceable_id
      t.string :reference_number
      t.decimal :total, precision: 10, scale: 2
      t.string :check_number
      t.text :description
      t.text :notes
      t.integer :status
      t.date :sent_date
      t.date :received_date
      t.string :stripe_invoice_id
      t.string :stripe_charge_id

      t.timestamps
    end
  end
end
