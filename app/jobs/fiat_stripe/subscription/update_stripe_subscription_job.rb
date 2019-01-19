class FiatStripe::Subscription::UpdateStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscribable)

    if subscribable.subscription
      product = subscribable.stripe_product

      correct_plan = Stripe::Plan.list({ product: product, amount: (subscription.subscription_monthly_rate * 100) }, api_key: subscribable.stripe_api_key).first

      if correct_plan
        item = subscribable.subscription.items.first
        item.plan = correct_plan.id
        item.save
      else
        new_plan = Stripe::Plan.create(
          { amount: subscribable.subscription_monthly_rate * 100,
            interval: "month",
            product: product,
            currency: "usd",
            nickname: "$#{subscribable.subscription_monthly_rate}/mo"
          },
          api_key: subscribable.stripe_api_key
        )
        item = subscribable.subscription.items.first
        item.plan = new_plan.id
        item.save
      end
    end
  end
end
