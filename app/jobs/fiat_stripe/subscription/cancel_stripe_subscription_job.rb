class FiatStripe::Subscription::CancelStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(subscription)
    if subscription
      sub = Stripe::Subscription.retrieve({ id: subscription.id }, api_key: subscribable.stripe_api_key)
      sub.delete
    end
  end
end
