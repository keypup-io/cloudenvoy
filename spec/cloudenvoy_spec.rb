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
    let(:gcp_msg) { instance_double('Cloudenvoy::Message') }

    before { expect(Cloudenvoy::PubSubClient).to receive(:publish).with(topic, payload, attrs).and_return(gcp_msg) }
    it { is_expected.to eq(gcp_msg) }
  end

  describe '.publishers' do
    subject { described_class.publishers }

    it { is_expected.to include(TestPublisher) }
  end

  describe '.subscribers' do
    subject { described_class.subscribers }

    it { is_expected.to include(TestSubscriber) }
  end

  describe '.setup_subscribers' do
    subject { described_class.setup_subscribers }

    let(:subscriber) { TestSubscriber }
    let(:subs) { Array.new(2) { instance_double('Cloudenvoy::Subscription') } }

    before do
      allow(described_class).to receive(:subscribers).and_return([subscriber])
      expect(subscriber).to receive(:setup).and_return(subs)
    end

    it { is_expected.to eq(subs) }
  end

  describe '.setup_publishers' do
    subject { described_class.setup_publishers }

    let(:publisher) { TestPublisher }
    let(:topics) { Array.new(2) { instance_double('Cloudenvoy::Topic') } }

    before do
      allow(described_class).to receive(:publishers).and_return([publisher])
      expect(publisher).to receive(:setup).and_return(topics)
    end

    it { is_expected.to eq(topics) }
  end
end
