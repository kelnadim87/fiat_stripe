module FiatStripe
  class InvoicesController < ActionController::Base
    include ActionView::Helpers::NumberHelper
    before_action :set_invoice, only: [:show, :edit, :update, :destroy]

    def index
    end

    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @invoice }
        # format.pdf do
        #   pdf = InvoicePdf.new(@invoice)
        #   send_data pdf.render, filename: "invoice_#{Organization.find(@invoice.organization_id).name.parameterize.underscore}_#{@invoice.created_at.strftime("%m-%d-%y")}.pdf", type: 'application/pdf'
        # end
      end
    end

    def new
      @invoice = Invoice.new

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @invoice }
      end
    end

    def create
      @invoice = Invoice.new(invoice_params)

      respond_to do |format|
        if @invoice.save
          format.html { redirect_to system_invoice_path(@invoice) }
          format.json { render json: @invoice, status: :created, location: @invoice }
        else
          format.html { render action: "new" }
          format.json { render json: @invoice.errors, status: :unprocessable_entity }
        end
      end
    end

    def edit
    end

    def update
      if params[:status]
        # For sending / receiving an invoice w/ AJAX from an invoice list
        @invoice.update(status: params[:status])
      else
        # For passing a form
        @invoice.update(invoice_params)
      end

      respond_to do |format|
        format.html { redirect_back(fallback_location: pending_system_invoices_path, notice: 'Success!') }
        format.js   { render :partial => 'invoices/update.js.erb' }
      end
    end

    def pending
      @invoices = Invoice.pending
    end

    def sent
      @invoices = Invoice.sent.order("sent_date DESC")
    end

    def received
      @invoices = Invoice.received.order("received_date DESC").order("sent_date DESC").order("total DESC")
    end

    def send_reminder
      # code
    end

    def destroy
      @invoice.destroy

      respond_to do |format|
        format.html { redirect_to pending_system_invoices_path, notice: 'Invoice successfully removed.' }
        format.json { head :no_content }
      end
    end

    private

      def set_invoice
        @invoice = Invoice.find(params[:id])
      end

      def invoice_params
        params.require(:invoice).permit(:invoiceable_type, :invoiceable_id, :reference_number, :total, :check_number, :description, :notes, :status, :due_date, :sent_date, :received_date, :stripe_invoice_id, :stripe_charge_id)
      end
  end
end
