class FiatStripe::Invoice::SendNoticeJob < FiatStripe::ApplicationJob
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  queue_as :default

  def perform(invoice, email_recipients, invoice_url)

    if invoice.sent? && !invoice.sent_date
      invoice.update(sent_date: Date.today)
      email_template_id = FiatStripe.invoice_notice_email_template_id
    elsif invoice.received? && !invoice.received_date
      invoice.update(received_date: Date.today)
      email_template_id = FiatStripe.invoice_receipt_email_template_id
    end

    items = invoice.invoice_items.map do |i|
      { item_description: i.description, item_amount: number_with_precision(i.sub_total, precision: 2) }
    end

    postmark_client = Postmark::ApiClient.new(FiatStripe.postmark_api_token)
    postmark_client.deliver_with_template(
    {:from=>FiatStripe.from_email_address,
     :to=>email_recipients,
     :template_id=>email_template_id,
     :template_model=>
      {"total"=>number_with_precision(invoice.total, precision: 2),
       "due_date"=>invoice.due_date.strftime("%B %e, %Y"),
       "invoiceable_name"=>invoice.invoiceable.name,
       "invoice_url"=>invoice_url,
       "reference_number"=>invoice.reference_number,
       "sent_date"=>invoice.sent_date.strftime("%B %e, %Y"),
       "description"=>invoice.description,
       "invoice_items"=>items
      }
    })
  end
end
