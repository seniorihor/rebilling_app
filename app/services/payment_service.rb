require 'net/http'
require 'uri'
require 'json'

# PaymentService is responsible for processing payments for subscriptions.
# It handles both full payments and remaining balance payments, and manages retry attempts
# in case of insufficient funds.
class PaymentService
  # An array of percentages used to reduce the payment amount on retries.
  RETRY_PERCENTAGES = [1.0, 0.75, 0.50, 0.25].freeze
  GATEAWAY_URL = 'http://localhost:3000/paymentIntents/create'.freeze

  attr_reader :subscription

  def initialize(subscription)
    @subscription = subscription
  end

  # If the subscription has a positive remaining balance, it processes the remaining payment.
  # Otherwise, it processes the full payment.
  def call
    if subscription.remaining_balance.positive?
      process_remaining_payment
    else
      process_payment
    end
  end

  private

  # Processes the payment for a subscription.
  #
  # This method calculates the amount to charge based on the subscription's retry attempts
  # and the predefined retry percentages. It then attempts to charge the card with the
  # calculated amount and logs the transaction.
  #
  # Depending on the response status, it handles the payment accordingly:
  # - 'success': Calls the handle_successful_payment method.
  # - 'insufficient_funds': Calls the retry_payment_with_reduced_amount method.
  # - 'failed': Handles the failed payment error.
  # - other statuses: Handles other payment errors.
  #
  # @return [void]
  def process_payment
    retry_percentage = RETRY_PERCENTAGES[@subscription.retry_attempts]
    amount_to_charge = @subscription.amount * retry_percentage
    response = charge_card(amount_to_charge)

    @subscription.logs.create!(amount: amount_to_charge, status: response['status'])

    case response['status']
    when 'success'
      handle_successful_payment(amount_to_charge)
    when 'insufficient_funds'
      retry_payment_with_reduced_amount
    when 'failed'
      @subscription.deactivate!
      # Handle failed payment error
    else
      @subscription.deactivate!
      # Handle other payment errors
    end
  end

  # Processes the remaining payment for a subscription by charging the card.
  # Logs the transaction and updates the subscription status based on the response.
  #
  # @return [void]
  def process_remaining_payment
    response = charge_card(subscription.remaining_balance)

    @subscription.logs.create!(amount: subscription.remaining_balance, status: response['status'])

    if response['status'] == 'success'
      subscription.activate!
    else
      subscription.deactivate!
    end
  end

  # Charges a card with the specified amount.
  #
  # @param amount [Integer] The amount to be charged.
  # @return [Hash] The parsed JSON response from the payment service.
  # @raise [JSON::ParserError] If the response body is not valid JSON.
  #
  # Example:
  #   charge_card(5000)
  #   # => {"status" => "success"}
  def charge_card(amount)
    uri = URI.parse(GATEAWAY_URL)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data("amount" => amount, "subscription_id" => @subscription.id)

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end

  # Handles the successful payment for a subscription.
  #
  # @param amount [Numeric] the amount paid.
  # @return [void]
  #
  # Updates the subscription status and remaining balance based on the payment amount.
  # If there is a remaining balance, the subscription status is set to :pending and the next retry attempt is scheduled.
  # If the payment covers the full amount, the subscription status is set to :active.
  def handle_successful_payment(amount)
    remaining_balance = @subscription.amount - amount

    if remaining_balance > 0
      @subscription.update(status: :pending, retry_attempts: 0, remaining_balance: remaining_balance, next_retry_at: 1.week.from_now)
    else
      @subscription.activate!
    end
  end

  # Retries the payment with a reduced amount based on the number of retry attempts.
  # If the number of retry attempts is less than the maximum allowed retries,
  # it increments the retry attempts and processes the payment again with lower amount.
  # If the maximum number of retry attempts is reached, it updates the subscription status to inactive.
  #
  # @return [void]
  def retry_payment_with_reduced_amount
    if @subscription.retry_attempts < RETRY_PERCENTAGES.size - 1
      @subscription.increment!(:retry_attempts)

      process_payment
    else
      @subscription.deactivate!
    end
  end
end
