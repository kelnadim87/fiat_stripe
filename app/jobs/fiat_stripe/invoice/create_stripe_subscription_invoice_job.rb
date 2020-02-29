class Invoice::CreateStripeSubscriptionInvoiceJob < ApplicationJob
  queue_as :default

  def perform(stripe_subscription_id, amount, paid_status, stripe_charge_id, stripe_invoice_id)
    sub = Subscription.find_by(stripe_subscription_id: stripe_subscription_id)
    invoice = Invoice.create(organization_id: sub.organization.id, total: amount, stripe_invoice_id: stripe_invoice_id, status: 'sent', sent_date: Date.today, description: "Monthly support plan (#{sub.support_plan.level.humanize}): #{Date.today.strftime("%B %Y")}")
    InvoiceItem.create(invoice_id: invoice.id, invoiceable_type: "SupportPlan", invoiceable_id: sub.support_plan.id, sub_total: amount)
    # QUESTION: Add more invoice items for each host, if any?
    if paid_status == true # If the invoice was immediately paid, mark it
      invoice.update(status: 'received', stripe_charge_id: stripe_charge_id)
    end
  end
end
