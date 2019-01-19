class FiatStripe::Subscription::CreateStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscribable)

    # Find the Stripe pricing plan for $0/mo on the Monthly Subscription product
    if Rails.env.development?
      plan = FiatStripe.test_default_plan_id.to_s
    elsif Rails.env.production?
      plan = FiatStripe.live_default_plan_id.to_s
    end

    stripe_subscription = Stripe::Subscription.create(
      { customer: subscribable.stripe_customer_id,
        trial_period_days: FiatStripe.trial_period_days,
        items: [
          { plan: plan }
        ]
      },
      api_key: subscribable.stripe_api_key
    )
  end
end
