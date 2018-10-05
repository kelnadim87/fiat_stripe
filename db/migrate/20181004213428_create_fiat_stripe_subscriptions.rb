class CreateFiatStripeSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :fiat_stripe_subscriptions do |t|

      t.timestamps
    end
  end
end
