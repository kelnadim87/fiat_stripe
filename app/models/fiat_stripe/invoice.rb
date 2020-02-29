module FiatStripe
  class Invoice < ApplicationRecord
    include Tokenable

    self.table_name = "fi_invoices"

    belongs_to :invoiceable, polymorphic: true

    has_many :invoice_items

    validates :invoiceable, presence: true

    # scope :seen, lambda { where(viewed: 1) }

    enum status: {
      pending: 0,
      sent: 1,
      received: 2
    }

    after_create :generate_reference_number
    after_commit -> { FiatStripe::Invoice::SendNoticeJob.set(wait: 5.seconds).perform_later(self, FiatStripe.email_template_id) }, on: :update
    # after_commit :send_receipt, on: :update

    def generate_reference_number
      o = [('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
      token = (0...7).map { o[rand(o.length)] }.join
      self.update(reference_number: token)
    end
  end
end
