require 'rails_helper'

RSpec.describe PaymentService, type: :service do
  let(:subscription) { create(:subscription, amount: 1000, retry_attempts: 0, remaining_balance: 0) }
  let(:service) { described_class.new(subscription) }

  describe '#call' do
    context 'when remaining balance is positive' do
      before { subscription.update(remaining_balance: 500) }

      it 'processes the remaining payment' do
        expect(service).to receive(:process_remaining_payment)
        service.call
      end
    end

    context 'when remaining balance is zero' do
      it 'processes the full payment' do
        expect(service).to receive(:process_payment)
        service.call
      end
    end
  end

  describe '#process_payment' do
    before do
      allow(service).to receive(:charge_card).and_return(response)
    end

    context 'when payment is successful' do
      let(:response) { { 'status' => 'success' } }

      it 'handles successful payment' do
        expect(service).to receive(:handle_successful_payment).with(1000)
        service.send(:process_payment)
      end

      it 'creates a log with the correct amount and status' do
        service.send(:process_payment)

        expect(subscription.logs).to contain_exactly(
          have_attributes(amount: 1000, status: 'success')
        )
      end
    end

    context 'when payment has insufficient funds' do
      let(:response) { { 'status' => 'insufficient_funds' } }

      it 'retries payment with reduced amount' do
        expect(service).to receive(:retry_payment_with_reduced_amount)
        service.send(:process_payment)
      end

      it 'creates a log with the correct amount and status' do
        service.send(:process_payment)

        expect(subscription.logs).to contain_exactly(
          have_attributes(amount: 1000, status: 'insufficient_funds'),
          have_attributes(amount: 750, status: 'insufficient_funds'),
          have_attributes(amount: 500, status: 'insufficient_funds'),
          have_attributes(amount: 250, status: 'insufficient_funds')
        )
      end
    end

    context 'when payment fails' do
      let(:response) { { 'status' => 'failed' } }

      it 'handles failed payment error' do
        # Add your expectations for handling failed payment error
        service.send(:process_payment)
      end

      it 'creates a log with the correct amount and status' do
        service.send(:process_payment)

        expect(subscription.logs).to contain_exactly(
          have_attributes(amount: 1000, status: 'failed')
        )
      end
    end

    context 'when payment has other errors' do
      let(:response) { { 'status' => 'error' } }

      it 'handles other payment errors' do
        # Add your expectations for handling other payment errors
        service.send(:process_payment)
      end

      it 'creates a log with the correct amount and status' do
        service.send(:process_payment)

        expect(subscription.logs).to contain_exactly(
          have_attributes(amount: 1000, status: 'error')
        )
      end
    end
  end

  describe '#process_remaining_payment' do
    before do
      allow(service).to receive(:charge_card).and_return(response)
      subscription.update(remaining_balance: 500)
    end

    context 'when payment is successful' do
      let(:response) { { 'status' => 'success' } }

      it 'updates subscription to active and sets remaining balance to zero' do
        service.send(:process_remaining_payment)
        expect(subscription.reload.status).to eq('active')
        expect(subscription.remaining_balance).to eq(0)
      end

      it 'creates a log with the correct amount and status' do
        service.send(:process_remaining_payment)

        expect(subscription.logs).to contain_exactly(
          have_attributes(amount: 500, status: 'success')
        )
      end
    end

    context 'when payment fails' do
      let(:response) { { 'status' => 'failed' } }

      it 'updates subscription to inactive' do
        service.send(:process_remaining_payment)
        expect(subscription.reload.status).to eq('inactive')
      end

      it 'creates a log with the correct amount and status' do
        service.send(:process_remaining_payment)

        expect(subscription.logs).to contain_exactly(
          have_attributes(amount: 500, status: 'failed')
        )
      end
    end
  end

  describe '#handle_successful_payment' do
    context 'when there is a remaining balance' do
      it 'updates subscription to pending and schedules next retry' do
        service.send(:handle_successful_payment, 750)
        expect(subscription.reload.status).to eq('pending')
        expect(subscription.remaining_balance).to eq(250)
        expect(subscription.next_retry_at).to be_within(1.second).of(1.week.from_now)
      end
    end

    context 'when payment covers the full amount' do
      it 'updates subscription to active' do
        service.send(:handle_successful_payment, 1000)
        expect(subscription.reload.status).to eq('active')
        expect(subscription.remaining_balance).to eq(0)
      end
    end
  end

  describe '#retry_payment_with_reduced_amount' do
    context 'when retry attempts are less than maximum allowed' do
      it 'increments retry attempts and processes payment again' do
        expect(service).to receive(:process_payment)
        service.send(:retry_payment_with_reduced_amount)
        expect(subscription.reload.retry_attempts).to eq(1)
      end

      it 'charges the correct reduced amount' do
        allow(service).to receive(:charge_card).and_return('status' => 'success')
        service.send(:retry_payment_with_reduced_amount)
        log = subscription.logs.last
        expect(log.amount).to eq(750) # 1000 * 0.75
      end
    end

    context 'when retry attempts are at the second retry' do
      before { subscription.update(retry_attempts: 1) }

      it 'increments retry attempts and processes payment again' do
        expect(service).to receive(:process_payment)
        service.send(:retry_payment_with_reduced_amount)
        expect(subscription.reload.retry_attempts).to eq(2)
      end

      it 'charges the correct reduced amount' do
        allow(service).to receive(:charge_card).and_return('status' => 'success')
        service.send(:retry_payment_with_reduced_amount)
        log = subscription.logs.last
        expect(log.amount).to eq(500) # 1000 * 0.50
      end
    end

    context 'when retry attempts are at the third retry' do
      before { subscription.update(retry_attempts: 2) }

      it 'increments retry attempts and processes payment again' do
        expect(service).to receive(:process_payment)
        service.send(:retry_payment_with_reduced_amount)
        expect(subscription.reload.retry_attempts).to eq(3)
      end

      it 'charges the correct reduced amount' do
        allow(service).to receive(:charge_card).and_return('status' => 'success')
        service.send(:retry_payment_with_reduced_amount)
        log = subscription.logs.last
        expect(log.amount).to eq(250) # 1000 * 0.25
      end
    end

    context 'when maximum retry attempts are reached' do
      before { subscription.update(retry_attempts: 3) }

      it 'updates subscription to inactive' do
        service.send(:retry_payment_with_reduced_amount)
        expect(subscription.reload.status).to eq('inactive')
      end
    end
  end
end
