# frozen_string_literal: true

RSpec.describe Cloudenvoy::PubSubClient do
  let(:backend) { class_double('Cloudenvoy::Backend::GooglePubSub') }

  describe '.backend' do
    subject { described_class.backend }

    before { described_class.instance_variable_set('@backend', nil) }

    context 'with test mode' do
      before { allow(Cloudenvoy::Testing).to receive(:enabled?).and_return(false) }
      it { is_expected.to eq(Cloudenvoy::Backend::MemoryPubSub) }
    end

    context 'with production mode' do
      it { is_expected.to eq(Cloudenvoy::Backend::GooglePubSub) }
    end
  end

  describe '.publish' do
    subject { described_class.publish(topic, payload, metadata) }

    let(:topic) { 'some-topic' }
    let(:payload) { { foo: 'bar' } }
    let(:metadata) { { some: 'attribute' } }
    let(:msg) { instance_double('Cloudenvoy::Message') }

    before { allow(described_class).to receive(:backend).and_return(backend) }
    before { expect(backend).to receive(:publish).with(topic, payload, metadata).and_return(msg) }
    it { is_expected.to eq(msg) }
  end

  describe '.upsert_subscription' do
    subject { described_class.upsert_subscription(topic, sub_name) }

    let(:topic) { 'some-topic' }
    let(:sub_name) { 'some.name' }
    let(:envoy_sub) { instance_double('Cloudenvoy::Subscription') }

    before { allow(described_class).to receive(:backend).and_return(backend) }
    before { expect(backend).to receive(:upsert_subscription).with(topic, sub_name).and_return(envoy_sub) }
    it { is_expected.to eq(envoy_sub) }
  end

  describe '.upsert_topic' do
    subject { described_class.upsert_topic(topic) }

    let(:topic) { 'some-topic' }
    let(:envoy_topic) { instance_double('Cloudenvoy::Topic') }

    before { allow(described_class).to receive(:backend).and_return(backend) }
    before { expect(backend).to receive(:upsert_topic).with(topic).and_return(envoy_topic) }
    it { is_expected.to eq(envoy_topic) }
  end
end
