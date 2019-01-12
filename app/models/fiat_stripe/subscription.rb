module FiatStripe
  class Subscription < ApplicationRecord
    include Tokenable

    self.table_name = "fi_stripe_subscriptions"

    belongs_to :subscriber, polymorphic: true

    validates :subscriber, presence: true

    after_touch :save
    after_commit -> { FiatStripe::Subscription::CreateStripeSubscriptionJob.set(wait: 5.seconds).perform_later(self) }, on: :create
    after_commit -> { FiatStripe::Subscription::UpdateStripeSubscriptionJob.set(wait: 5.seconds).perform_later(self) }, on: :update, if: :is_stripe_pricing_inaccurate? # This runs when an associated support plan is updated, too, b/c of touch
    after_commit -> { FiatStripe::Subscription::CancelStripeSubscriptionJob.set(wait: 5.seconds).perform_later(self.stripe_subscription_id) }, on: :destroy

    def stripe_subscription
      # if self.stripe_subscription_id?
      #   Rails.cache.fetch("#{cache_key}/stripe_subscription", expires_in: 30.days) do
      #     subscription = Stripe::Subscription.retrieve({id: self.stripe_subscription_id}, api_key: self.stripe_api_key)
      #   end
      # end
    end

    def stripe_plan
      if self.stripe_subscription
        self.stripe_subscription.items.first.plan.id
      end
    end

    def stripe_product
      if self.stripe_subscription
        self.stripe_subscription.items.first.plan.product
      end
    end

    def is_stripe_pricing_inaccurate?
      if self.stripe_subscription
        if self.stripe_subscription.items.first.plan.amount != (self.rate * 100)
          true
        else
          false
        end
      end
    end
  end
end
