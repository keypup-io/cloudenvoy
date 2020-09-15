# frozen_string_literal: true

RSpec.describe Cloudenvoy::SubscriberController, type: :controller do
  routes { Cloudenvoy::Engine.routes }

  describe 'POST #receive' do
    subject { post :receive, body: payload.merge(token: auth_token).to_json, as: mime_type }

    let(:payload) do
      {
        'message' => {
          'data' => Base64.strict_encode64(msg_obj.to_json)
        },
        'subscription' => sub_uri
      }
    end
    let(:mime_type) { :json }
    let(:request_body) { payload.to_json }
    let(:expected_payload) { payload }

    let(:msg_obj) { { 'foo' => 'bar' } }
    let(:sub_uri) { 'projects/some-proj/subscriptions/test-sub' }
    let(:auth_token) { Cloudenvoy::Authenticator.verification_token }

    context 'with valid subscriber' do
      before do
        expect(Cloudenvoy::Subscriber).to receive(:execute_from_descriptor)
          .with(expected_payload)
          .and_return(true)
      end
      it { is_expected.to be_successful }
    end

    context 'with processing errors' do
      before do
        allow(Cloudenvoy::Subscriber).to receive(:execute_from_descriptor)
          .with(expected_payload)
          .and_raise(ArgumentError)
      end
      it { is_expected.to have_http_status(:unprocessable_entity) }
    end

    context 'with invalid subscriber' do
      before do
        allow(Cloudenvoy::Subscriber).to receive(:execute_from_descriptor)
          .with(expected_payload)
          .and_raise(Cloudenvoy::InvalidSubscriberError)
      end
      it { is_expected.to have_http_status(:not_found) }
    end

    context 'with no authentication' do
      let(:auth_token) { nil }

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context 'with invalid authentication' do
      let(:auth_token) { '123' }

      it { is_expected.to have_http_status(:unauthorized) }
    end
  end
end
