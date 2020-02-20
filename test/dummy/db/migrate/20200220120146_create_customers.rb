class CreateCustomers < ActiveRecord::Migration[5.2]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :stripe_customer_id
      t.string :stripe_card_token
      t.boolean :remove_card

      t.timestamps
    end
  end
end
