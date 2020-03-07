class FiatStripe::Subscription::CreateStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscribable, plan_id: nil)

    if plan_id
      # Override environment defaults with specific plan ID value
      plan = plan_id.to_s
    else
      if Rails.env.development?
        plan = FiatStripe.configuration.test_default_plan_id.to_s
      elsif Rails.env.production?
        plan = FiatStripe.configuration.live_default_plan_id.to_s
      end
    end

    stripe_subscription = Stripe::Subscription.create(
      { customer: subscribable.stripe_customer_id,
        trial_period_days: FiatStripe.configuration.trial_period_days,
        items: [
          { plan: plan }
        ]
      },
      api_key: subscribable.stripe_api_key
    )
  end
end
