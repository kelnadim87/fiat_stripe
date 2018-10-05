class CreateFiatStripeSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :fiat_stripe_subscriptions do |t|
      t.string :subscriber_type
      t.integer :subscriber_id
      t.string :stripe_subscription_id
      t.string :token

      t.timestamps
    end
  end
end
