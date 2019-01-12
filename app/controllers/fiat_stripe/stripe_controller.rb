module FiatStripe
  class StripeController < ActionController::Base

    def create_stripe_customer_id
      # TODO: Figure out how to handle this
      object_class = params[:object_class].constantize
      object_id = params[:object_id].to_i

      customer = Stripe::Customer.create(
        { description: params[:name],
          email: params[:email]
        },
        api_key: object_class.find(object_id).stripe_api_key
      )

      object_class.find(object_id).update_attributes(stripe_customer_id: customer.id)
      redirect_back(fallback_location: nil, notice: 'Your payment profile was created.')
    end

  end
end
