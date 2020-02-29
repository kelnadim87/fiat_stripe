class FiatStripe::Invoice::SendNotificationJob < FiatStripe::ApplicationJob
  # include ActionView::Helpers::TextHelper
  queue_as :default

  def perform(invoice, email_template_id: nil)
    # Checks status and see if `sent_date` exists
    # Note: Failing to check the `sent_date` value will result in recursion

    if self.saved_change_to_status? && self.sent? && !self.sent_date

      self.update(sent_date: Date.today)

      client = Postmark::ApiClient.new(Rails.application.credentials.postmark[:api_token])

      items = self.invoice_items.map do |i|
        # TODO: Update description to something more specific
        if i.invoiceable_type == "SupportPlan"
          # TODO: Add host itemizations, e.g.:
          # hosts = i.invoiceable.hosts.count
          { description: "Support Plan", amount: number_with_precision(i.sub_total, precision: 2) }
        else
          { description: i.invoiceable_type, amount: number_with_precision(i.sub_total, precision: 2) }
        end
      end

      users = Organization.find(self.organization_id).billing_emails
      if users.any?
        recipients = users
      else
        recipients = "hello@fiatinsight.com"
      end

      client.deliver_with_template(
      {:from=>"hello@fiatinsight.com",
       :to=>recipients,
       :template_id=>16372674,
       :template_model=>
        {"total"=>number_with_precision(self.total, precision: 2),
         #"due_date"=>"due_date_Value",
         #"purchase_date"=>"purchase_date_Value",
         "organization_name"=>Organization.find(self.organization_id).name,
         "action_url"=>"https://fiatinsight.com/client/invoices/#{self.id}",
         "ref_number"=>self.ref_number,
         "date"=>self.sent_date.strftime("%B %e, %Y"),
         "notes"=>self.description,
         "invoice_details"=>items
        }
      })
    end
  end
