# Fiat Stripe

> Currently installed on [Parish.es](https://github.com/fiatinsight/parish-app) and [BrokrQuotes](https://github.com/fiatinsight/brokrquotes/).

This engine is designed to be used by [@fiatinsight](https://fiatinsight.com) developers on Rails projects that need to connect paying entities with Stripe in a flexible way.

## Getting started

Add this line to your application's `Gemfile`:

```ruby
gem 'fiat_stripe'
```

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
FiatStripe.trial_period_days = 0
```

Then mount the engine in your `routes.rb` file (either at a top level or within a namespace):

```ruby
mount FiatStripe::Engine => "/fiat_stripe", as: "fiat_stripe"
```

To include all the [helpers](https://github.com/fiatinsight/fiat_stripe/tree/master/app/helpers), add this line in your `ApplicationController`:

```ruby
helper FiatStripe::Engine.helpers
```

## Usage

### Stripeable

The [`Stripeable`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/models/concerns/stripeable.rb) concern for models does the work of ensuring a class is able to act as a Stripe customer. Call it using `include Stripeable`. You'll also need to make sure that any classes in your application that will connect as Stripe customers have the following database fields: `stripe_customer_id`, `stripe_card_token`, and `remove_card`.

Here's a sample migration for this:

    $ rails g migration add_stripe_fields_to_xyz stripe_customer_id:string stripe_card_token:string remove_card:boolean

Per [Stripe's recommendations](https://stripe.com/docs/connect/authentication#authentication-via-api-keys), this engine passes an API key with each request. Per-request authentication requires you to set the relevant API key on the model that you want to use in a method called `stripe_api_key`. For example, you could easily set the key for one model to listen to the application credentials: `Rails.configuration.stripe[:secret_key]`; and the key for another model as pursuant to the first (in this case, through a `belongs_to` relationship):

```ruby
def stripe_api_key
  if Rails.env.production?
    self.organization.stripe_live_secret_key
  else
    self.organization.stripe_test_secret_key
  end
end
```

### Subscribable

The [`Subscribable`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/models/concerns/subscribable.rb) concern can be included on any model for which you want to generate and manage a subscription. You can invoke jobs to create, update, and destroy Stripe subscriptions directly from your `Subscribable` model's callback cycle.

#### Creating a subscription

To create a subscription, include:

```ruby
after_commit -> { FiatStripe::Subscription::CreateStripeSubscriptionJob.set(wait: 5.seconds).perform_later(self) }, on: :create
```

This invokes the [`CreateStripeSubscriptionJob`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/jobs/fiat_stripe/subscription/create_stripe_subscription_job.rb), which creates a new subscription with the environment-specific plan ID you set in your initializer.

> Hint: Creating a plan for $0/mo as a baseline for creating a new subscription is helpful, so that you can instantiate the subscription prior to setting a final rate.

#### Updating a subscription

To update a subscription, call [`UpdateStripeSubscriptionJob`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/jobs/fiat_stripe/subscription/update_stripe_subscription_job.rb) by using:

```ruby
after_commit -> { FiatStripe::Subscription::UpdateStripeSubscriptionJob.set(wait: 5.seconds).perform_later(self) }, on: :update, if: :is_stripe_pricing_inaccurate?
```

`:is_stripe_pricing_inaccurate?` is a method available via `Subscribable` that checks the subscription plan against a model's `subscription_monthly_rate` method. This is set _on your model_ in the main application to provide granular control for dynamic pricing outside of the engine.

#### Cancelling a subscription

To cancel a subscription, hit [`CancelStripeSubscriptionJob`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/jobs/fiat_stripe/subscription/cancel_stripe_subscription_job.rb) by putting:

```ruby
after_commit -> { FiatStripe::Subscription::CancelStripeSubscriptionJob.set(wait: 5.seconds).perform_later(self.subscription) }, on: :destroy
```

> Note: The argument to pass, here, is the subscription itself, not the `Subscribable` instance.

### Individual Stripe actions

The [`StripeController`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/controllers/fiat_stripe/stripe_controller.rb) provides actions for things like creating a Stripe customer ID, transacting a one-time payment, etc.

For example, a one-time payment form could be set up like this:

```ruby
= simple_form_for :one_time_payment, url: fiat_stripe.one_time_payment_stripe_index_path(object_class: "Organization", object_id: @organization.id, customer_id: @organization.stripe_customer_id, receipt_email: @organization.email) do |f|
  = f.input :amount
  = f.input :description
  = f.button :button, "Submit", type: :submit, class: 'btn', data: { confirm: "Are you sure you want to complete this one-time payment?" }
end
```

## Development

To build this gem for the first time, run `gem build fiat_stripe.gemspec` from the project folder.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fiatinsight/fiat_stripe.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
