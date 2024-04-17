# frozen_string_literal: true

RSpec.describe Cloudenvoy::PubSubClient do
  let(:backend) { class_double(Cloudenvoy::Backend::GooglePubSub) }

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
    let(:msg) { instance_double(Cloudenvoy::Message) }

    before { allow(described_class).to receive(:backend).and_return(backend) }
    before { expect(backend).to receive(:publish).with(topic, payload, metadata).and_return(msg) }
    it { is_expected.to eq(msg) }
  end

  describe '.publish_all' do
    subject { described_class.publish_all(topic, msg_args) }

    let(:topic) { 'some-topic' }
    let(:msg_args) { [[{ foo: 'bar1' }, { some: 'attribute1' }], [{ foo: 'bar2' }, { some: 'attribute2' }]] }
    let(:msgs) { [instance_double(Cloudenvoy::Message), instance_double(Cloudenvoy::Message)] }

    before do
      allow(described_class).to receive(:backend).and_return(backend)
      msg_args.each_slice(Cloudenvoy::Config::BATCH_MAX_MSG_COUNT).with_index do |slice, index|
        msg_ret = msgs.each_slice(Cloudenvoy::Config::BATCH_MAX_MSG_COUNT).to_a[index]
        expect(backend).to receive(:publish_all).with(topic, slice).and_return(msg_ret)
      end
    end

    context "with less than #{Cloudenvoy::Config::BATCH_MAX_MSG_COUNT} messages" do
      it { is_expected.to eq(msgs) }
    end

    context "with more than #{Cloudenvoy::Config::BATCH_MAX_MSG_COUNT} messages" do
      let(:msg_count) { Cloudenvoy::Config::BATCH_MAX_MSG_COUNT + 10 }
      let(:msg_args) { Array.new(msg_count) { |n| [{ foo: "bar#{n}" }, { some: "attribute#{n}" }] } }
      let(:msgs) { Array.new(msg_count) { instance_double(Cloudenvoy::Message) } }

      it { is_expected.to eq(msgs) }
    end
  end

  describe '.upsert_subscription' do
    subject { described_class.upsert_subscription(topic, sub_name, opts) }

    let(:topic) { 'some-topic' }
    let(:sub_name) { 'some.name' }
    let(:opts) { { foo: 'bar' } }
    let(:envoy_sub) { instance_double(Cloudenvoy::Subscription) }

    before { allow(described_class).to receive(:backend).and_return(backend) }
    before { expect(backend).to receive(:upsert_subscription).with(topic, sub_name, opts).and_return(envoy_sub) }
    it { is_expected.to eq(envoy_sub) }
  end

  describe '.upsert_topic' do
    subject { described_class.upsert_topic(topic) }

    let(:topic) { 'some-topic' }
    let(:envoy_topic) { instance_double(Cloudenvoy::Topic) }

    before { allow(described_class).to receive(:backend).and_return(backend) }
    before { expect(backend).to receive(:upsert_topic).with(topic).and_return(envoy_topic) }
    it { is_expected.to eq(envoy_topic) }
  end
end
