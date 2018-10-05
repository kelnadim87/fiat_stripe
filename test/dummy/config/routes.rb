Rails.application.routes.draw do
  mount FiatStripe::Engine => "/fiat_stripe"
end
