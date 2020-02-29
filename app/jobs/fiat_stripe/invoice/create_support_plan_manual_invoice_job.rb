class Invoice::CreateSupportPlanManualInvoiceJob < ApplicationJob
  queue_as :default

  def perform(support_plan)

    # Note: No support plan should end up here unless it's attached to a subscription

    if support_plan.subscription.monthly?
      invoice = Invoice.create(organization_id: support_plan.organization.id, total: support_plan.monthly_rate, status: 'pending', description: "Monthly support plan (#{support_plan.level.humanize}): #{Date.today.strftime("%B %Y")}")
      InvoiceItem.create(invoice_id: invoice.id, invoiceable_type: "SupportPlan", invoiceable_id: support_plan.id, sub_total: support_plan.monthly_rate)
    elsif support_plan.subscription.annual?
      invoice = Invoice.create(organization_id: support_plan.organization.id, total: support_plan.monthly_rate * 12, status: 'pending', description: "Annual support plan (#{support_plan.level.humanize}): #{Date.today.strftime("%B %Y")}")
      InvoiceItem.create(invoice_id: invoice.id, invoiceable_type: "SupportPlan", invoiceable_id: support_plan.id, sub_total: support_plan.monthly_rate * 12)
    end

    # TODO: (Maybe) add more invoice items for each host, if any? Just to record that they were included on the payment, without a value...
  end
end
