# Fiat Stripe

> Currently installed on [Parish.es](https://github.com/fiatinsight/parish-app), [CatholicStock](https://github.com/fiatinsight/catholic-stock), and [BrokrQuotes](https://github.com/fiatinsight/brokrquotes/).

This engine is designed to be used by [@fiatinsight](https://fiatinsight.com) developers on Rails projects that need to connect paying entities with Stripe in a flexible way.

## Getting started

Add this line to your application's `Gemfile`:

```ruby
gem 'fiat_stripe'
```

You'll need to configure the `stripe` gem like normal. Here's an example of how you can write a flexible `config/initializers/stripe.rb` file:

```ruby
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

Stripe.api_key = Rails.configuration.stripe[:secret_key]
```

> Note: You'll need to configure `StripeEvent.signing_secret` to handle webhooks with `stripe_event`.

Create an initializer at `config/initializers/fiat_stripe.rb` to set some required global variables:

```ruby
FiatStripe.live_default_plan_id = "plan_id"
FiatStripe.test_default_plan_id = "plan_id"
FiatStripe.trial_period_days = 0
FiatStripe.postmark_api_token = "postmark_api_token"
FiatStripe.from_email_address = "email@email.com"
FiatStripe.invoice_notice_email_template_id = "postmark_template_id"
FiatStripe.invoice_reminder_email_template_id = "postmark_template_id"
FiatStripe.invoice_receipt_email_template_id = "postmark_template_id"
```

Then mount the engine in your `routes.rb` file (either at a top level or within a namespace):

```ruby
mount FiatStripe::Engine => "/fiat_stripe", as: "fiat_stripe"
```

> You'll also need to mount `stripe_event` as explained, [here](https://github.com/integrallis/stripe_event#install).

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
after_commit -> { FiatStripe::Subscription::CreateStripeSubscriptionJob.set(wait: 5.seconds).perform_later(self, plan_id: "123abc") }, on: :create
```

> Note: `plan_id` is optional, and will default to `nil` if not included.

This invokes the [`CreateStripeSubscriptionJob`](https://github.com/fiatinsight/fiat_stripe/blob/master/app/jobs/fiat_stripe/subscription/create_stripe_subscription_job.rb), which creates a new subscription with the plan ID you passed or, if left out, with the environment-specific plan ID you set in your initializer.

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

### Invoices

You can generate and manage local invoices using the `Invoice` and `InvoiceItem` classes. This allows for a mixed invoice processing workflow (e.g., handling check payments alongside automatic payment) and enables synchronization with Stripe payments via the `stripe_event` gem / Stripe webhooks API.

#### Configuration

Add the following to any classes in your main application that you want to handle invoices for:

```ruby
has_many :fi_invoices, as: :invoiceable, dependent: :destroy, class_name: "FiatStripe::Invoice"
```

You'll need to make sure any `invoiceable` class has a `name` attribute / method. You'll also need to set up an `email_recipients` method on each `invoiceable` class to provide an array of email addresses for invoice notifications, as well as an `invoice_url` method. For example:

```ruby
def email_recipients
  User.where(id: [OrganizationUser.where(organization_id: self.id, billing: 1).pluck(:user_id)]).pluck(:email)
end

def invoice_url(invoice_id)
  "https://yourwebsite.com/customer/#{self.id}/invoices/#{invoice_id}"
end
```

Classes you want to add to invoice items (e.g., products) should include:

```ruby
has_many :fi_invoice_items, as: :invoice_itemable, dependent: :destroy, class_name: "FiatStripe::InvoiceItem"
```

Saving or removing a new item will recalculate the invoice total. You can pass in custom information to the item `description` field, based on the type of thing you're itemizing.

#### Notices

When an invoice is saved, its status is checked. If the invoice is moved to `sent` and doesn't have a sent date, `FiatStripe::Invoice::SendNoticeJob` adds the date, and issues an email notification with the correct information. When an invoice is marked `received`, the job runs and similarly adds a received date and sends a receipt email.

#### Stripe integration

You can choose what actions you want to perform on your local invoices for Stripe payments using the Stripe webhooks API. Add something like the following to your application's `config/initializers/stripe.rb` file:

```ruby
StripeEvent.configure do |events|

  # Create invoices for automatic subscriptions (and try to mark them paid)
  events.subscribe 'invoice.created' do |event|
    # Note: ActiveJob can't serialize the `event` object, so break it apart
    stripe_subscription_id = event.data.object.subscription
    amount = event.data.object.amount_due / 100
    paid_status = event.data.object.paid
    stripe_charge_id = event.data.object.charge
    stripe_invoice_id = event.data.object.id

    # 1. Find Stripe subscription by ID

    subscription = Stripe::Subscription.list(stripe_subscription_id, api_key: Rails.configuration.stripe[:secret_key])

    # 2. Find Subscribable object by Stripe customer ID

    stripe_customer_id = subscription.customer
    subscribable = Organization.find_by(stripe_customer_id: stripe_customer_id) # Change to whatever your application's Subscribable object is

    # 3. Create invoice for Subscribable object

    # description = # Set a custom invoice description here (optional)
    description ||= nil

    # invoice_items = # Add invoice items here (optional)
    # E.g.:
    # { class_name: "Product",
    #   id: subscribable.product.id,
    #   sub_total: subscribable.product.monthly_rate,
    #   description: "Monthly product description"
    # }
    invoice_items ||= nil

    FiatStripe::Invoice::CreateSubscriptionInvoiceJob.set(wait: 10.seconds).perform_later(stripe_subscription_id, amount, paid_status, stripe_charge_id, stripe_invoice_id, description, invoice_items)
  end

  # Listen for paid invoices (e.g., failed, delayed) and mark them off
  events.subscribe 'invoice.payment_succeeded' do |event|
    stripe_invoice_id = event.data.object.id
    stripe_charge_id = event.data.object.charge

    if FiatStripe::Invoice.find_by(stripe_invoice_id: stripe_invoice_id)
      FiatStripe::Invoice::UpdateSubscriptionInvoiceJob.set(wait: 10.seconds).perform_later(stripe_invoice_id, stripe_charge_id)
    end
  end

  # Report failed charges
  events.subscribe 'charge.failed' do |event|
    customer_id = event.data.object.customer
    failure_code = event.data.object.failure_code
    failure_message = event.data.object.failure_message

    # code

    # TODO: Make this work w/ email option / args: FiatStripe::Charge::ReportFailedChargeJob.set(wait: 10.seconds).perform_later(customer_id, failure_code, failure_message)
  end

  # Successful charges
  events.subscribe 'charge.succeeded' do |event|
    # code
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
