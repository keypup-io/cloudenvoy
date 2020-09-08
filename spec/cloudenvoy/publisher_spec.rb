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
    let(:gcp_msg) { instance_double('Google::Cloud::PubSub::Message') }

    before { expect(publisher_class).to receive(:new).with(msg_args: msg_args).and_return(publisher) }
    before { expect(publisher).to receive(:publish).and_return(gcp_msg) }
    it { is_expected.to eq(gcp_msg) }
  end

  describe '.setup' do
    subject { publisher_class.setup }

    let(:gcp_topic) { instance_double('Google::Cloud::PubSub::Topic') }

    context 'with default topic' do
      before do
        expect(Cloudenvoy::PubSubClient).to receive(:upsert_topic)
          .with(publisher_class.default_topic)
          .and_return(gcp_topic)
      end

      it { is_expected.to eq(gcp_topic) }
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

  describe '#publish' do
    subject { publisher.publish }

    let(:topic) { 'foo-topic' }
    let(:payload) { { formatted: 'payload' } }
    let(:metadata) { { some: 'attrs' } }
    let(:gcp_msg) { instance_double('Google::Cloud::PubSub::Message', message_id: '1234') }

    let(:ret_message) do
      Cloudenvoy::Message.new(
        id: gcp_msg.message_id,
        topic: topic,
        payload: payload,
        metadata: metadata
      )
    end

    before do
      expect(publisher).to receive(:topic).with(*msg_args).and_return(topic)
      expect(publisher).to receive(:payload).with(*msg_args).and_return(payload)
      expect(publisher).to receive(:metadata).with(*msg_args).and_return(metadata)
      expect(Cloudenvoy::PubSubClient).to receive(:publish).with(topic, payload, metadata).and_return(gcp_msg)
    end
    after { expect(publisher).to have_attributes(message: ret_message) }

    it { is_expected.to eq(ret_message) }
  end
end
