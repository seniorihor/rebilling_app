require 'rails_helper'

RSpec.describe SubscriptionRebillingJob, type: :job do
  let(:subscription) { create(:subscription, status: status, next_retry_at: next_retry_at) }

  describe '#perform' do
    context 'when subscription is pending and next_retry_at is in the past' do
      let(:status) { 'pending' }
      let(:next_retry_at) { 1.hour.ago }

      it 'processes the payment' do
        expect_any_instance_of(PaymentService).to receive(:call)
        described_class.perform_now(subscription.id)
      end
    end

    context 'when subscription is not pending' do
      let(:status) { [ 'active', 'failed' ].sample }
      let(:next_retry_at) { 1.hour.ago }

      it 'does not process the payment' do
        expect_any_instance_of(PaymentService).not_to receive(:call)
        described_class.perform_now(subscription.id)
      end
    end

    context 'when next_retry_at is in the future' do
      let(:status) { 'pending' }
      let(:next_retry_at) { 1.hour.from_now }

      it 'does not process the payment' do
        expect_any_instance_of(PaymentService).not_to receive(:call)
        described_class.perform_now(subscription.id)
      end
    end
  end
end
