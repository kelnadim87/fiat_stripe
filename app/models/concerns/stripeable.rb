module Stripeable
  extend ActiveSupport::Concern

  included do
    after_commit -> { FiatStripe::Customer::CreateCustomerIdJob.set(wait: 5.seconds).perform_later(self) }, on: :create
    # before_commit -> { FiatStripe::Customer::UpdateCustomerJob.set(wait: 5.seconds).perform_later(self) }, on: :update
    before_commit :update_payment_method, on: :update
  end

  def update_payment_method
    # Move this to a job?
    # TODO: Update this method to work w/ bank accounts
    begin
      if self.saved_change_to_stripe_card_token? && self.stripe_card_token? && self.stripe_customer_id?
        token = self.stripe_card_token
        customer = Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key)
        customer.sources.create(source: self.stripe_card_token)
        customer.save
      elsif saved_change_to_remove_card? && remove_card && stripe_customer_id
        customer = Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key)
        customer.sources.retrieve(customer.sources.data.first.id).delete
        customer.save
        self.update(remove_card: nil, stripe_card_token: nil)
      end
    # See: https://stripe.com/docs/api/errors/handling
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]

      puts "Status is: #{e.http_status}"
      puts "Type is: #{err[:type]}"
      puts "Charge ID is: #{err[:charge]}"
      # The following fields are optional
      puts "Code is: #{err[:code]}" if err[:code]
      puts "Decline code is: #{err[:decline_code]}" if err[:decline_code]
      puts "Param is: #{err[:param]}" if err[:param]
      puts "Message is: #{err[:message]}" if err[:message]
    rescue Stripe::RateLimitError => e
      # Too many requests made to the API too quickly
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
    rescue => e
      # Something else happened, completely unrelated to Stripe
    end
  end

  def has_source?
    if self.stripe_customer_id?
      if Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key).sources.any?
        true
      else
        false
      end
    else
      false
    end
  end

  def has_card?
    if self.stripe_customer_id?
      if Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key).sources.data.first.object == "card"
        true
      else
        false
      end
    else
      false
    end
  end

  def has_bank_account?
    if self.stripe_customer_id?
      if Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key).sources.data.first.object == "bank_account"
        true
      else
        false
      end
    else
      false
    end
  end

  def is_billable?
    if self.stripe_customer_id? && self.has_source?
      true
    else
      false
    end
  end

  def payment_name
    if self.is_billable?
      Rails.cache.fetch("#{cache_key}/payment_name", expires_in: 7.days) do
        if self.has_card?
          name = Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key).sources.data.first.brand
          "#{name}"
        elsif self.has_bank_account?
          # Something...
        end
      end
    end
  end

  def payment_last4
    if self.is_billable?
      Rails.cache.fetch("#{cache_key}/payment_last4", expires_in: 7.days) do
        if self.has_card?
          last4 = Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key).sources.data.first.last4
          "#{last4}"
        elsif self.has_bank_account?
          # Something...
        end
      end
    end
  end

  def card_expiration # TODO: Redo this to accommodate banks?
    if self.stripe_customer_id? && self.stripe_card_token?
      Rails.cache.fetch("#{cache_key}/card_expiration", expires_in: 7.days) do
        exp_month = Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key).sources.data.first.exp_month
        exp_year = Stripe::Customer.retrieve({id: self.stripe_customer_id}, api_key: self.stripe_api_key).sources.data.first.exp_year
        "#{exp_month}/#{exp_year}"
      end
    end
  end

  def past_payments
    if self.stripe_customer_id?
      Stripe::Charge.list({customer: self.stripe_customer_id}, api_key: self.stripe_api_key)
    end
  end
end
