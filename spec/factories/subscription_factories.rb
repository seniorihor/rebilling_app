FactoryBot.define do
  factory :subscription do
    amount { 100.0 }
    next_retry_at { nil }
  end
end
