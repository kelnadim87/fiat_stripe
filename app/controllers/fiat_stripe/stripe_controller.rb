module FiatStripe
  class StripeController < ActionController::Base

    def create_stripe_customer_id
      object_class = params[:object_class].constantize
      object_id = params[:object_id].to_i

      customer = Stripe::Customer.create({
        description: params[:name],
        email: params[:email]
        },
        api_key: object_class.find(object_id).stripe_api_key
      )

      object_class.find(object_id).update_attributes(stripe_customer_id: customer.id)
      redirect_back(fallback_location: nil, notice: 'Your payment profile was created.')
    end

    def one_time_payment
      object_class = params[:object_class].constantize
      object_id = params[:object_id].to_i

      charge = Stripe::Charge.create({
        customer: params[:customer_id], # Ideally, this would be further encrypted somehow
        amount: (params[:one_time_payment][:amount].to_d * 100).to_i,
        currency: 'usd',
        description: params[:one_time_payment][:description],
        receipt_email: params[:email],
        # source: token,
        },
        api_key: object_class.find(object_id).stripe_api_key
      )

      redirect_back(fallback_location: nil, notice: 'Your payment was created!')
    end

  end
end
