class Subscription::CreateStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscription)

    # Find the Stripe pricing plan for $0/mo on the Monthly Subscription product
    if Rails.env.development?
      plan = "plan_DeD7LO9GI9aZkm"
    elsif Rails.env.production?
      plan = "plan_DeD8h1XbaHyHOS"
    end

    stripe_subscription = Stripe::Subscription.create(
      customer: subscription.parish.stripe_customer_id,
      trial_period_days: 14,
      items: [
        {
          plan: plan
        }
      ]
    )
    subscription.update_attributes(stripe_subscription_id: stripe_subscription.id)
  end
end
