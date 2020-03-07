# See: http://lizabinante.com/blog/creating-a-configurable-ruby-gem/
require 'fiat_stripe/configuration'
require "fiat_stripe/engine"

module FiatStripe
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
