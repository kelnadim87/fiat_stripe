# Fiat Stripe

Short description and motivation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fiat_stripe'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fiat_stripe

## Setup

You'll need to configure the `stripe` and `stripe_event` gems like you would normally. You'll also need to make sure that any classes in your application that will connect to Stripe customers have the following database fields: `name`, `stripe_customer_id`, `stripe_card_token`, and `remove_card`.

To include all the helpers, add this line in your `ApplicationController`:

```ruby
helper FiatStripe::Engine.helpers
```

### Stripeable

The `Stripeable` concern for models does the work of ensuring a class is able to act as a Stripe customer. Call it using `include Stripeable`.

### Subscriptions

## Development

To build this gem for the first time, run `gem build fiat_stripe.gemspec` from the project folder.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fiatinsight/fiat_stripe.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
