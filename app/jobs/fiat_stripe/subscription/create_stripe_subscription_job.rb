class FiatStripe::Subscription::CreateStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscription)

    # Find the Stripe pricing plan for $0/mo on the Monthly Subscription product
    if Rails.env.development?
      plan = FiatStripe.test_default_plan_id.to_s
    elsif Rails.env.production?
      plan = FiatStripe.live_default_plan_id.to_s
    end

    stripe_subscription = Stripe::Subscription.create(
      customer: subscription.subscriber.stripe_customer_id,
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
