require "fiat_stripe/engine"

module FiatStripe
  mattr_accessor :live_default_plan_id
  mattr_accessor :test_default_plan_id
  mattr_accessor :trial_period_days
  mattr_accessor :postmark_api_token
  mattr_accessor :from_email_address
  mattr_accessor :invoice_notice_email_template_id
  mattr_accessor :invoice_reminder_email_template_id
  mattr_accessor :invoice_receipt_email_template_id
end
