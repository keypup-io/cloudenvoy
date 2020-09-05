# frozen_string_literal: true

RSpec.describe Cloudenvoy do
  describe '::VERSION' do
    subject { Cloudenvoy::VERSION }

    it { is_expected.not_to be nil }
  end

  describe '.logger' do
    subject { described_class.logger }

    it { is_expected.to eq(described_class.config.logger) }
  end

  describe '.publish' do
    subject { described_class.publish(topic, payload, attrs) }

    let(:topic) { 'some-topic' }
    let(:payload) { { some: 'payload' } }
    let(:attrs) { { filter: 'attr' } }
    let(:gcp_msg) { instance_double('Google::Cloud::PubSub::Message') }

    before { expect(Cloudenvoy::PubSubClient).to receive(:publish).with(topic, payload, attrs).and_return(gcp_msg) }
    it { is_expected.to eq(gcp_msg) }
  end
end
