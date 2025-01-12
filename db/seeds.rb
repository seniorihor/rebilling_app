subscriptions = [
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current },
  { amount: 1000, status: 'pending', retry_attempts: 0, remaining_balance: 0, next_retry_at: Time.current }
].map do |attrs|
  Subscription.create!(attrs)
end

# Simulate rebilling attempts and display logs
Subscription.all.each do |subscription|
  puts "\nSubscription ##{subscription.id} (#{subscription.status})#{' (OLD)' if subscriptions.exclude?(subscription)}:"

  subscription.update!(next_retry_at: Time.current) if subscription.next_retry_at

  SubscriptionRebillingJob.perform_now(subscription.id)

  subscription.logs.order(:id).each do |log|
    puts "    - Log ##{log.id} (#{log.status}): #{log.amount}"
  end

  puts "  Current status:  #{subscription.reload.status}"
end
