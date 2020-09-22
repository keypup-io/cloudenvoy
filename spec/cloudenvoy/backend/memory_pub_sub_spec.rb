# frozen_string_literal: true

require 'cloudenvoy/backend/memory_pub_sub'

RSpec.describe Cloudenvoy::Backend::MemoryPubSub do
  let(:message) { instance_double('Cloudenvoy::Message') }

  describe '.queue' do
    subject { described_class.queue(topic) }

    let(:topic) { 'foo' }

    before { described_class.queue(topic).push(message) }
    it { is_expected.to eq([message]) }
  end

  describe '.clear' do
    subject { described_class.queue(topic) }

    let(:topic) { 'foo' }

    before { described_class.queue(topic).push(message) }
    before { described_class.clear(topic) }

    it { is_expected.to be_empty }
  end

  describe '.clear_all' do
    subject { [described_class.queue(topic1), described_class.queue(topic2)] }

    let(:topic1) { 'foo' }
    let(:topic2) { 'bar' }

    before do
      [topic1, topic2].each { |t| described_class.queue(t).push(message) }
      described_class.clear_all
    end

    it { is_expected.to match([be_empty, be_empty]) }
  end

  describe '.publish' do
    subject { described_class.publish(topic, payload, metadata) }

    let(:topic) { 'foo' }
    let(:payload) { { 'some' => 'payload' } }
    let(:metadata) { { 'some' => 'meta' } }
    let(:expected_msg) do
      {
        class: Cloudenvoy::Message,
        topic: topic,
        payload: payload,
        metadata: metadata
      }
    end

    before { described_class.clear_all }
    after { expect(described_class.queue(topic)).to match([have_attributes(expected_msg)]) }
    it { is_expected.to have_attributes(expected_msg) }
  end

  describe '.upsert_subscription' do
    subject { described_class.upsert_subscription(topic, name, foo: 'bar') }

    let(:topic) { 'foo' }
    let(:name) { 'some.sub.name' }
    let(:expected_sub) do
      {
        class: Cloudenvoy::Subscription,
        name: name
      }
    end

    it { is_expected.to have_attributes(expected_sub) }
  end

  describe '.upsert_topic' do
    subject { described_class.upsert_topic(topic) }

    let(:topic) { 'foo' }
    let(:expected_topic) do
      {
        class: Cloudenvoy::Topic,
        name: topic
      }
    end

    it { is_expected.to have_attributes(expected_topic) }
  end
end
