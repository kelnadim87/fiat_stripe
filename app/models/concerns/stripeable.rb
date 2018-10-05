module Stripeable
  extend ActiveSupport::Concern

  included do
    before_commit :update_stripe, on: :update
  end

  def has_source?
    if self.stripe_customer_id?
      if Stripe::Customer.retrieve(self.stripe_customer_id).sources.any?
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
      if Stripe::Customer.retrieve(self.stripe_customer_id).sources.data.first.object == "card"
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
      if Stripe::Customer.retrieve(self.stripe_customer_id).sources.data.first.object == "bank_account"
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

  def update_stripe
    # TODO: Update this method to work w/ bank accounts
    if self.saved_change_to_stripe_card_token? && self.stripe_card_token? && self.stripe_customer_id?
      token = self.stripe_card_token
      customer = Stripe::Customer.retrieve(self.stripe_customer_id)
      customer.sources.create(source: self.stripe_card_token)
      customer.save
    elsif saved_change_to_remove_card? && remove_card && stripe_customer_id
      customer = Stripe::Customer.retrieve(self.stripe_customer_id)
      customer.sources.retrieve(customer.sources.data.first.id).delete
      customer.save
      self.update_attributes(remove_card: nil, stripe_card_token: nil)
    end
  end

  def payment_name
    if self.is_billable?
      Rails.cache.fetch("#{cache_key}/payment_name", expires_in: 7.days) do
        if self.has_card?
          name = Stripe::Customer.retrieve(self.stripe_customer_id).sources.data.first.brand
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
          last4 = Stripe::Customer.retrieve(self.stripe_customer_id).sources.data.first.last4
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
        exp_month = Stripe::Customer.retrieve(self.stripe_customer_id).sources.data.first.exp_month
        exp_year = Stripe::Customer.retrieve(self.stripe_customer_id).sources.data.first.exp_year
        "#{exp_month}/#{exp_year}"
      end
    end
  end
end
