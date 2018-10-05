class Subscription::CancelStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(stripe_subscription_id)
    if stripe_subscription_id
      sub = Stripe::Subscription.retrieve(stripe_subscription_id)
      sub.delete
    end
  end
end
