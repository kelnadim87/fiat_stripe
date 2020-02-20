class Customer < ApplicationRecord
  include Stripeable
  include Subscribable

  def stripe_api_key
    "sk_test_4MoJ30a0CVEtm5yMJyfpxnNr"
  end
end
