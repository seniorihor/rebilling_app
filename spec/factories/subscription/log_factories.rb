FactoryBot.define do
  factory :subscription_log do
    association :subscription
    amount { rand(100) }
    status { Subscription::STATUSES.sample }
  end
end
