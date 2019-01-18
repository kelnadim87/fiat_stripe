# Fiat Stripe

This engine is designed to be used by [@fiatinsight](https://fiatinsight.com) developers on Rails projects that need to connect paying entities with Stripe in a flexible way.

## Getting started

Add this line to your application's `Gemfile`:

```ruby
gem 'fiat_stripe'
```

Then `bundle` and run the required migrations directly by typing:

    $ rake db:migrate

You'll need to configure the `stripe` and `stripe_event` gems like normal. Here's an example of how you can write `config/initializers/stripe.rb` to be flexible for testing:

```ruby
if Rails.env.development?
  Rails.configuration.stripe = {
    publishable_key: Rails.application.credentials.development[:stripe][:publishable_key],
    secret_key: Rails.application.credentials.development[:stripe][:secret_key]
  }
elsif Rails.env.production?
  Rails.configuration.stripe = {
    publishable_key: Rails.application.credentials.production[:stripe][:publishable_key],
    secret_key: Rails.application.credentials.production[:stripe][:secret_key]
  }
end
```

Create an initializer at `config/initializers/fiat_stripe.rb` to set some required global variables:

```ruby
FiatStripe.live_default_plan_id = "plan_id"
FiatStripe.test_default_plan_id = "plan_id"
```

To include all the helpers, add this line in your `ApplicationController`:

```ruby
helper FiatStripe::Engine.helpers
```

## Usage

### Stripeable

The [`Stripeable`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/models/concerns/stripeable.rb) concern for models does the work of ensuring a class is able to act as a Stripe customer. Call it using `include Stripeable`. You'll also need to make sure that any classes in your application that will connect as Stripe customers have the following database fields: `stripe_customer_id`, `stripe_card_token`, and `remove_card`.

Here is a sample migration generation for this:

    $ rails g migration add_stripe_fields_to_xyz stripe_customer_id:string stripe_card_token:string remove_card:boolean

Per (Stripe's recommendations)[https://stripe.com/docs/connect/authentication#authentication-via-api-keys], an API key is passed with each request. Per-request authentication requires you to set the relevant API key on the model that you want to use as `stripe_api_key`. For example, you could easily set the key for one model to listen to the application credentials: `Rails.configuration.stripe[:secret_key]`; and the key for another model as pursuant to the first (in this case, through a `belongs_to` relationship):

```ruby
def stripe_api_key
  if Rails.env.production?
    self.organization.stripe_live_secret_key
  else
    self.organization.stripe_test_secret_key
  end
end
```

### Subscriptions

Subscriptions handle the records and logic for controlling Stripe subscriptions in your app. And they connect directly to Stripe subscriptions to actively manage pricing.

You can choose how to initiate a subscription. They're not automatically created when a new Stripe customer ID is created. So, for example, on a `Stripeable` class, you could run:

```ruby
after_commit :create_subscription, on: :create

def create_subscription
  FiatStripe::Subscription.create(subscriber_type: "ClassName", subscriber_id: self.id)
end
```

Or you could manually create subscriptions using a separate controller action, etc.

Extend the `Subscription` model to include `rate` logic by adding a file at `app/decorators/models/fiat_stripe/subscription_decorator.rb`:

```ruby
FiatStripe::Subscription.class_eval do
  def rate
    # Put logic here to calculate rate per payment period
    # Note: monthly vs annual payment periods are determined by the plan_id that's active
    # E.g., self.subscriber.rate
  end
end
```

## Development

To build this gem for the first time, run `gem build fiat_stripe.gemspec` from the project folder.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fiatinsight/fiat_stripe.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
