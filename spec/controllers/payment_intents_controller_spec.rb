require 'ostruct'
require 'rails_helper'

RSpec.describe PaymentIntentsController, type: :controller do
  describe "POST #create" do
    let(:subscription) { create(:subscription) }

    subject { post :create, params: { subscription_id: subscription.id, amount: 100.0 } }

    context "when payment intent is successful" do
      before do
        allow_any_instance_of(PaymentIntentsController).to receive(:emulate_payment_gateway).and_return(OpenStruct.new(success?: true))
      end

      it "creates a payment intent with success" do
        subject

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['status']).to eq('success')
      end
    end

    context "when payment intent has insufficient funds" do
      before do
        allow_any_instance_of(PaymentIntentsController).to receive(:emulate_payment_gateway).and_return(OpenStruct.new(success?: false, error_code: 'insufficient_funds'))
      end

      it "creates a payment intent with insufficient funds" do
        subject

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['status']).to eq('insufficient_funds')
      end
    end

    context "when payment intent fails" do
      before do
        allow_any_instance_of(PaymentIntentsController).to receive(:emulate_payment_gateway).and_return(OpenStruct.new(success?: false, error_code: 'other_error'))
      end

      it "creates a payment intent with failed status" do
        subject

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['status']).to eq('failed')
      end
    end
  end
end
