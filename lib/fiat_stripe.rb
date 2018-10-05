require "fiat_stripe/engine"

module FiatStripe
  mattr_accessor :live_default_plan_id
  mattr_accessor :test_default_plan_id
end
