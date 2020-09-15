# frozen_string_literal: true

RSpec.describe Cloudenvoy::Publisher do
  let(:publisher_class) { TestPublisher }
  let(:msg_args) { [{ foo: 'bar' }, { bar: 'foo' }] }
  let(:publisher) { publisher_class.new(msg_args: msg_args) }

  describe '.cloudenvoy_options_hash' do
    subject { publisher_class.cloudenvoy_options_hash }

    let(:opts) { { foo: 'bar' } }
    let!(:original_opts) { publisher_class.cloudenvoy_options_hash }

    before { publisher_class.cloudenvoy_options(opts) }
    after { publisher_class.cloudenvoy_options(original_opts) }
    it { is_expected.to eq(Hash[opts.map { |k, v| [k.to_sym, v] }]) }
  end

  describe '.default_topic' do
    subject { publisher_class.default_topic }

    it { is_expected.to eq(publisher_class.cloudenvoy_options_hash.fetch(:topic)) }
  end

  describe '.publish' do
    subject { publisher_class.publish(*msg_args) }

    let(:publisher) { instance_double('TestPublisher') }
    let(:msg) { instance_double('Cloudenvoy::Message') }

    before { expect(publisher_class).to receive(:new).with(msg_args: msg_args).and_return(publisher) }
    before { expect(publisher).to receive(:publish).and_return(msg) }
    it { is_expected.to eq(msg) }
  end

  describe '.setup' do
    subject { publisher_class.setup }

    let(:envoy_topic) { instance_double('Cloudenvoy::Topic') }

    context 'with default topic' do
      before do
        expect(Cloudenvoy::PubSubClient).to receive(:upsert_topic)
          .with(publisher_class.default_topic)
          .and_return(envoy_topic)
      end

      it { is_expected.to eq(envoy_topic) }
    end

    context 'with no default topic' do
      before do
        allow(publisher_class).to receive(:default_topic).and_return(nil)
        expect(Cloudenvoy::PubSubClient).not_to receive(:upsert_topic)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.new' do
    subject { publisher }

    it { is_expected.to have_attributes(msg_args: msg_args) }
  end

  describe '#topic' do
    subject { publisher.topic(*msg_args) }

    it { is_expected.to eq(publisher_class.default_topic) }
  end

  describe '#metadata' do
    subject { publisher.metadata(*msg_args) }

    it { is_expected.to eq({}) }
  end

  describe '#logger' do
    subject { publisher.logger }

    it { is_expected.to be_a(Cloudenvoy::PublisherLogger) }
    it { is_expected.to have_attributes(loggable: publisher) }
  end

  describe '#publishing_duration' do
    subject { publisher.publishing_duration }

    let(:now) { Time.now }
    let(:publishing_started_at) { now - 10.0005 }
    let(:publishing_ended_at) { now }

    before do
      publisher.publishing_started_at = publishing_started_at
      publisher.publishing_ended_at = publishing_ended_at
    end

    context 'with timestamps set' do
      it { is_expected.to eq((publishing_ended_at - publishing_started_at).ceil(3)) }
    end

    context 'with no publishing_started_at' do
      let(:publishing_started_at) { nil }

      it { is_expected.to eq(0.0) }
    end

    context 'with no publishing_ended_at' do
      let(:publishing_ended_at) { nil }

      it { is_expected.to eq(0.0) }
    end
  end

  describe '#publish' do
    subject(:publish) { publisher.publish }

    let(:topic) { 'foo-topic' }
    let(:payload) { { formatted: 'payload' } }
    let(:metadata) { { some: 'attrs' } }
    let(:ret_message) do
      Cloudenvoy::Message.new(
        id: '123',
        topic: topic,
        payload: payload,
        metadata: metadata
      )
    end

    before do
      expect(publisher).to receive(:topic).with(*msg_args).and_return(topic)
      expect(publisher).to receive(:payload).with(*msg_args).and_return(payload)
      expect(publisher).to receive(:metadata).with(*msg_args).and_return(metadata)
      allow(Cloudenvoy::PubSubClient).to receive(:publish).with(topic, payload, metadata).and_return(ret_message)
    end

    context 'with successful publish' do
      after { expect(publisher).to have_attributes(message: ret_message) }
      it { is_expected.to eq(ret_message) }
    end

    context 'with server middleware chain' do
      before { Cloudenvoy.config.publisher_middleware.add(TestMiddleware) }
      after { expect(publisher.middleware_called).to be_truthy }
      it { is_expected.to eq(ret_message) }
    end

    context 'with runtime error' do
      let(:error) { StandardError.new('some-message') }

      before { allow(Cloudenvoy::PubSubClient).to receive(:publish).and_raise(error) }
      before { expect(publisher).to receive(:on_error).with(error) }
      it { expect { publish }.to raise_error(error) }
    end
  end
end
