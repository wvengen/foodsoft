#
# This is a quick approach to get Mollie payments working without modifying
# foodsoft's database model. Transactions are not stored while in process,
# only on success. Failed transactions leave no trace in the database,
# but they are logged in the server log.
#
# Mollie's payment metadata contains the user id, so that a financial
# transaction can be created on success for that user and ordergroup.
#
# Perhaps a cleaner approach would be to create a financial transaction
# without amount zero when the payment process starts, and keep track
# of the state using that. Then the transaction id would be enough to
# process it, and also an error message could be given.
# But that would also litter financial transactions when not finished.
#
# Or start using activemerchant
#
class Payments::MollieController < ApplicationController
  before_action -> { require_plugin_enabled FoodsoftMollie }
  skip_before_action :authenticate, only: [:check]
  before_action :get_ordergroup, only: [:new, :create]
  before_action :accept_return_to, only: [:new]

  def new
    @amount = params[:amount] || [0, -@ordergroup.get_available_funds].min
    @amount = [params[:min], @amount].max if params[:min]
  end

  def create
    # store parameters so we can redirect to original form on problems
    session[:mollie_params] = params.select {|k,v| %w(amount label title fixed min text).include?(k)}

    amount = params[:amount]
    amount = [params[:min], amount].max if params[:min]

    payment = Mollie::Payment.create(
      amount:       { 'value' => format_amount(amount), 'currency' => FoodsoftMollie.currency },
      description:  "#{@current_user.ordergroup.id}, #{FoodsoftConfig[:name]}",
      redirect_url: result_payments_mollie_url,
      webhook_url:  check_payments_mollie_url,
      metadata:     { user_id: @current_user.id },
      api_key:      FoodsoftMollie.api_key
    )

    logger.info "Mollie start: #{amount} for ##{@current_user.id} (#{@current_user.display}), payment id #{payment.id}"
    session[:mollie_last_payment_id] = payment.id

    redirect_to payment.checkout_url
  end

  def check
    payment_id = params.require(:id)
    payment = Mollie::Payment.get(payment_id, api_key: FoodsoftMollie.api_key)
    user_id = payment.metadata.user_id
    logger.debug { "Mollie check: #{payment.inspect}" }
    logger.info "Mollie check for user ##{user_id}: id #{payment_id}, status #{payment.status}"

    if payment.paid?
      user = User.find(user_id)
      note = self.transaction_note(payment_id)
      if !transaction_exist?(user.ordergroup, note)
        amount = payment.amount.value
        # TODO handle financial transaction class
        @transaction = FinancialTransaction.new(user: user, ordergroup: user.ordergroup, amount: amount, note: note)
        @transaction.add_transaction!
      else
        logger.info "Transaction #{payment_id} for user ##{user.id} (#{user.display}) already exists."
      end
    end
    render status: 200, plain: "Ok"
  end

  def result
    payment_id = session[:mollie_last_payment_id]
    # if payment id is empty, the transaction will not be found, which is ok
    note = self.transaction_note(payment_id)
    if transaction_exist?(current_user.ordergroup, note)
      logger.info "Mollie result: payment #{payment_id} succeeded"
      session.delete(:mollie_params)
      session.delete(:mollie_last_payment_id)
      redirect_to_return_or root_path, notice: I18n.t('payments.mollie.controller.result.notice')
    else
      logger.info "Mollie result: payment #{payment_id} failed"
      # redirect to form with same parameters as original page
      pms = { foodcoop: FoodsoftConfig.scope }.merge((session[:mollie_params] or {}))
      session.delete(:mollie_params)
      session.delete(:mollie_last_payment_id)
      redirect_to new_payments_mollie_path(pms), :alert => I18n.t('payments.mollie.controller.result.failed')
    end
  end

  def cancel
    redirect_to_return_or root_path
  end

  protected

  def transaction_note(transaction_id)
    # this is _not_ translated, because this exact string is used to find the transaction
    "Online payment (Mollie #{transaction_id})"
  end

  def get_ordergroup
    # note that the current user may technically have no ordergroup
    @ordergroup = current_user.ordergroup
  end

  # Mollie requires the value to have the correct number of decimals. For now, use two.
  def format_amount(amount)
    '%.02f' % amount
  end

  def transaction_exist?(ordergroup, note)
    ordergroup.financial_transactions
      .where('created_on > ?', 1.week.ago) # only recent ones for performance
      .where(note: note)
      .exists?
  end

  # TODO move this to ApplicationController, use it in SessionController too
  # TODO use a stack of return_to urls
  def accept_return_to
    session[:return_to] = nil # or else an unfollowed previous return_to may interfere
    return unless params[:return_to].present?
    if params[:return_to].starts_with?(root_path) or params[:return_to].starts_with?(root_url)
      session[:return_to] = params[:return_to]
    end
  end
  def redirect_to_return_or(fallback_url, options={})
    if session[:return_to].present?
      redirect_to_url = session[:return_to]
      session[:return_to] = nil
    else
      redirect_to_url = fallback_url
    end
    redirect_to redirect_to_url, options
  end
end
