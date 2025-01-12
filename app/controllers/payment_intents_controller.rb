require 'ostruct'

class PaymentIntentsController < ApplicationController
  def create
    subscription = Subscription.find(params[:subscription_id])
    amount = params[:amount].to_d

    response = emulate_payment_gateway(subscription, amount)

    render json: { status: response_status(response) }
  end

  private

  def emulate_payment_gateway(subscription, amount)
    # Emulate the logic to charge the card using a payment gateway API
    # Return a response object with success? and error_code methods

    success, error_code = [
      [true, nil],
      [false, 'insufficient_funds'],
      [false, 'other_error']
    ].sample

    OpenStruct.new(success?: success, error_code: error_code)
  end

  def response_status(response)
    if response.success?
      'success'
    elsif response.error_code == 'insufficient_funds'
      'insufficient_funds'
    else
      'failed'
    end
  end
end
