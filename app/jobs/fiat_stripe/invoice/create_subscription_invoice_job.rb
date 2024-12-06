class FiatStripe::Invoice::CreateSubscriptionInvoiceJob < ApplicationJob
  queue_as :default

  def perform(stripe_subscription_id, amount, paid_status, stripe_charge_id, stripe_invoice_id, description: nil, invoice_items: nil)
    # sub = Subscription.find_by(stripe_subscription_id: stripe_subscription_id)

    invoice = FiatStripe::Invoice.create(invoiceable_type: subscribable.class.name, invoiceable_id: subscribable.id, total: amount, stripe_invoice_id: stripe_invoice_id, status: 'sent', sent_date: Date.today, description: description)

    if invoice_items
      invoice_items.each do |i|
        FiatStripe::InvoiceItem.create(invoice_id: invoice.id, invoice_itemable_type: i.class_name, invoice_itemable_id: i.id, sub_total: i.sub_total, description: i.description)
      end
    end

    if paid_status == true # If the invoice was immediately paid, mark it so
      invoice.update(status: 'received', stripe_charge_id: stripe_charge_id)
    end
  end
end
