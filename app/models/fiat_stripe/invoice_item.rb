module FiatStripe
  class InvoiceItem < ApplicationRecord
    include Tokenable

    self.table_name = "fi_invoice_items"

    belongs_to :invoice
    belongs_to :invoice_itemable, polymorphic: true

    validates :invoice, :invoice_itemable, :sub_total, presence: true

    after_save :calculate_total
    after_destroy :calculate_total

    def global_invoice_itemable
      self.invoice_itemable.to_global_id if self.invoice_itemable.present?
    end

    def global_invoice_itemable=(invoice_itemable)
      self.invoice_itemable = GlobalID::Locator.locate invoice_itemable
    end

    def calculate_total
      new_total = self.invoice.invoice_items.sum(:sub_total)
      self.invoice.update(total: new_total)
    end
  end
end
