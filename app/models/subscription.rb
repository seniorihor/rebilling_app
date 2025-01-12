class Subscription < ApplicationRecord
  STATUSES = %i[active inactive pending].freeze

  has_many :logs, class_name: "Subscription::Log", dependent: :destroy

  scope :pending, -> { where(status: :pending) }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :retry_attempts, numericality: { only_integer: true, less_than_or_equal_to: 4 }

  # Dynamically define boolean methods for each status
  STATUSES.each do |status|
    define_method("#{status}?") do
      self.status == status.to_s
    end
  end

  def activate!
    update!(status: :active, retry_attempts: 0, remaining_balance: 0, next_retry_at: nil)
  end

  def deactivate!
    update!(status: :inactive, next_retry_at: nil)
  end
end
