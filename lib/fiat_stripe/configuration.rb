module FiatStripe
  class Configuration
    attr_accessor :live_default_plan_id, :test_default_plan_id, :trial_period_days, :postmark_api_token, :from_email_address, :invoice_notice_email_template_id, :invoice_reminder_email_template_id, :invoice_receipt_email_template_id

    def initialize
      @live_default_plan_id = nil
      @test_default_plan_id = nil
      @trial_period_days = nil
      @postmark_api_token = nil
      @from_email_address = nil
      @invoice_notice_email_template_id = nil
      @invoice_receipt_email_template_id = nil
      @invoice_reminder_email_template_id = nil
    end
  end
end
