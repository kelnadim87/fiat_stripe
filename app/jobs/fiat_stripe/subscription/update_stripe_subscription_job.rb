class FiatStripe::Subscription::UpdateStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscription)
    if subscription.stripe_subscription_id?
      product = subscription.stripe_product

      correct_plan = Stripe::Plan.list(product: product, amount: (subscription.monthly_rate * 100)).first

      if correct_plan
        item = subscription.stripe_subscription.items.first
        item.plan = correct_plan.id
        item.save
      else
        new_plan = Stripe::Plan.create(
          amount: subscription.monthly_rate * 100,
          interval: "month",
          product: product,
          currency: "usd",
          nickname: "$#{subscription.monthly_rate}/mo"
        )
        item = subscription.stripe_subscription.items.first
        item.plan = new_plan.id
        item.save
      end
    end
  end
end
