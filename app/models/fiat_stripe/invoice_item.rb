module FiatStripe
  class InvoiceItem < ApplicationRecord
    include Tokenable

    self.table_name = "fi_invoice_items"

    belongs_to :invoice

    # after_commit -> { FiatNotifications::Notification::RelayJob.set(wait: 5.seconds).perform_later(self) }, on: :create
  end
end
