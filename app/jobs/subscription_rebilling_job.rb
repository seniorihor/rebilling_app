class SubscriptionRebillingJob < ApplicationJob
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find(subscription_id)

    if subscription.pending? && subscription.next_retry_at <= Time.current
      PaymentService.new(subscription).call
    end
  end
end
