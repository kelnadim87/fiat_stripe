require 'test_helper'

module FiatStripe
  class Concerns::Stripeable < ActiveSupport::TestCase
    test "should create Stripe customer" do
      customer = Customer.create(name: "Test customer")
      assert customer.save, "Customer didn't save"
    end
  end
end
