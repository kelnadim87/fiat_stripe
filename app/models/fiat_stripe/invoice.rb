module FiatStripe
  class Invoice < ApplicationRecord
    include Tokenable

    self.table_name = "fi_invoices"

    belongs_to :invoiceable, polymorphic: true
    has_many :invoice_items

    validates :invoiceable, :due_date, presence: true

    enum status: {
      pending: 0,
      sent: 1,
      received: 2
    }

    after_create :generate_reference_number
    after_commit -> { FiatStripe::Invoice::SendNoticeJob.set(wait: 5.seconds).perform_later(self, self.invoiceable.email_recipients, self.invoiceable.invoice_url(self.id)) }, on: :update, if: :status_updated?

    def generate_reference_number
      o = [('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
      token = (0...7).map { o[rand(o.length)] }.join
      self.update(reference_number: token)
    end

    def status_updated?
      if self.saved_change_to_status?
        true
      else
        false
      end
    end
  end
end
