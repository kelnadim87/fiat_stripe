module FiatStripe
  class StripeController < ActionController::Base

    def create_stripe_customer_id
      customer = Stripe::Customer.create(
        description: params[:name],
        email: params[:email]
      )

      # TODO: Figure out how to handle this
      object_class = params[:object_class].constantize
      object_id = params[:object_id].to_i
      object_class.find(object_id).update_attributes(stripe_customer_id: customer.id)
      redirect_back(fallback_location: nil, notice: 'Your payment profile was created.')
    end

  end
end
