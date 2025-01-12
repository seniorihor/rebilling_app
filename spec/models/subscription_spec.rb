require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe 'associations' do
    it { should have_many(:logs).class_name('Subscription::Log').dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_numericality_of(:retry_attempts).only_integer.is_less_than_or_equal_to(4) }
  end

  describe 'scopes' do
    let!(:pending_subscription) { create(:subscription, status: :pending) }
    let!(:active_subscription) { create(:subscription, status: :active) }

    it 'returns only pending subscriptions' do
      expect(Subscription.pending).to include(pending_subscription)
      expect(Subscription.pending).not_to include(active_subscription)
    end
  end

  describe 'constants' do
    it 'defines STATUSES' do
      expect(Subscription::STATUSES).to eq([:active, :inactive, :pending])
    end
  end
end

describe 'status methods' do
  Subscription::STATUSES.each do |status|
    describe "##{status}?" do
      let(:subscription) { build(:subscription, status: status.to_s) }

      it "returns true when status is #{status}" do
        expect(subscription.send("#{status}?")).to be true
      end

      it "returns false when status is not #{status}" do
        (Subscription::STATUSES - [status]).each do |other_status|
          subscription.status = other_status.to_s
          expect(subscription.send("#{status}?")).to be false
        end
      end
    end
  end
end

describe 'instance methods' do
  let(:subscription) { create(:subscription, status: :pending, retry_attempts: 3, remaining_balance: 100, next_retry_at: Time.current) }

  describe '#activate!' do
    before { subscription.activate! }

    it 'sets the status to active' do
      expect(subscription.status).to eq('active')
    end

    it 'resets retry_attempts to 0' do
      expect(subscription.retry_attempts).to eq(0)
    end

    it 'resets remaining_balance to 0' do
      expect(subscription.remaining_balance).to eq(0)
    end

    it 'sets next_retry_at to nil' do
      expect(subscription.next_retry_at).to be_nil
    end
  end

  describe '#deactivate!' do
    before { subscription.deactivate! }

    it 'sets the status to inactive' do
      expect(subscription.status).to eq('inactive')
    end

    it 'sets next_retry_at to nil' do
      expect(subscription.next_retry_at).to be_nil
    end
  end
end
