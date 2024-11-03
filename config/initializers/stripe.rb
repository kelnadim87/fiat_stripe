require 'stripe'
require 'stripe_event'

if Rails.env.development?
  Rails.configuration.stripe = {
    :publishable_key => Rails.application.credentials.development[:stripe][:publishable_key],
    :secret_key => Rails.application.credentials.development[:stripe][:secret_key]
  }
  StripeEvent.signing_secret = Rails.application.credentials.development[:stripe][:signing_secret]
elsif Rails.env.production?
  Rails.configuration.stripe = {
    :publishable_key => Rails.application.credentials.production[:stripe][:publishable_key],
    :secret_key => Rails.application.credentials.production[:stripe][:secret_key]
  }
  StripeEvent.signing_secret = Rails.application.credentials.production[:stripe][:signing_secret]
end

# Rails.configuration.stripe = {
#   publishable_key: Rails.application.credentials.stripe[:publishable_key],
#   secret_key: Rails.application.credentials.stripe[:secret_key]
# }
# StripeEvent.signing_secret = Rails.application.credentials.stripe[:signing_secret]

Stripe.api_key = Rails.configuration.stripe[:secret_key]

# StripeEvent.configure do |events|
#   events.subscribe 'charge.failed' do |event|
#     # Define subscriber behavior based on the event object
#     event.class       #=> Stripe::Event
#     event.type        #=> "charge.failed"
#     event.data.object #=> #<Stripe::Charge:0x3fcb34c115f8>
#   end
#
#   events.all do |event|
#     # Handle all event types - logging, etc.
#   end
# end
