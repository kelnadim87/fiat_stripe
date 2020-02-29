class Invoice::UpdateStripeSubscriptionInvoiceJob < ApplicationJob
  queue_as :default

  def perform(stripe_invoice_id, stripe_charge_id)
    invoice = Invoice.find_by(stripe_invoice_id: stripe_invoice_id)
    invoice.update(status: 'received', stripe_charge_id: stripe_charge_id)
  end
end
