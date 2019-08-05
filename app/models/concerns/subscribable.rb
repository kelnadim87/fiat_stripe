module Subscribable
  extend ActiveSupport::Concern

  # included do
  #   # Callbacks here...
  # end

  def subscription
    # Rails.cache.fetch("#{cache_key}/subscription", expires_in: 30.days) do
      Stripe::Customer.retrieve({ id: self.stripe_customer_id }, api_key: self.stripe_api_key).subscriptions.first
    # end
  end

  def stripe_plan
    if self.subscription
      self.subscription.items.first.plan.id
    end
  end

  def stripe_product
    if self.subscription
      self.subscription.items.first.plan.product
    end
  end

  def is_stripe_pricing_inaccurate?
    if self.subscription
      if self.subscription.items.first.plan.amount != (self.subscription_monthly_rate * 100)
        true
      else
        false
      end
    end
  end
end
