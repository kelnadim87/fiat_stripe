class FiatStripe::Charge::ReportFailedChargeJob < FiatStripe::ApplicationJob
  queue_as :default

  def perform(customer_id, failure_code, failure_message)

    org = Organization.find_by(stripe_customer_id: customer_id)

    client = Slack::Web::Client.new

    client.chat_postMessage(channel: '#billing', text: "Charge failed for *#{org.name}* (#{failure_code}): #{failure_message}", as_user: true)
  end
end
