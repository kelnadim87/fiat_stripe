FiatStripe::Engine.routes.draw do
  resources :stripe do
    post :create_stripe_customer_id, on: :collection
  end
end
