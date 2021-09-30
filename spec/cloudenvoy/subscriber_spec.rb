# frozen_string_literal: true

RSpec.describe Cloudenvoy::Subscriber do
  let(:subscriber_class) { TestSubscriber }
  let(:msg_id) { '1234' }
  let(:payload) { { 'username' => 'john' } }
  let(:metadata) { { 'some' => 'attrs' } }
  let(:topic) { 'foo-topic' }
  let(:sub_uri) { "projects/some-proj/subscriptions/some-app.#{subscriber_class.to_s.underscore}.#{topic}" }
  let(:message) { Cloudenvoy::Message.new(id: msg_id, payload: payload, metadata: metadata, sub_uri: sub_uri) }
  let(:subscriber) { subscriber_class.new(message: message) }

  let(:descriptor_sub) { sub_uri }
  let(:descriptor) do
    {
      'message' => {
        'attributes' => metadata,
        'data' => Base64.strict_encode64(payload.to_json),
        'message_id' => msg_id
      },
      'subscription' => descriptor_sub
    }
  end

  describe '.from_sub_uri' do
    subject { described_class.from_sub_uri(sub_uri) }

    context 'with valid subscriber' do
      it { is_expected.to eq(TestSubscriber) }
    end

    context 'with invalid subscriber' do
      let(:subscriber_class) { String }

      it { is_expected.to be_nil }
    end
  end

  describe '.parse_sub_uri' do
    subject { described_class.parse_sub_uri(sub_uri) }

    context 'with hyphened topic' do
      let(:topic) { 'foo-bar-baz-topic' }

      it { is_expected.to eq([subscriber_class.to_s.underscore, topic]) }
    end

    context 'with dotted topic' do
      let(:topic) { 'foo.bar.baz.topic' }

      it { is_expected.to eq([subscriber_class.to_s.underscore, topic]) }
    end
  end

  describe '.execute_from_descriptor' do
    subject(:execute) { described_class.execute_from_descriptor(descriptor) }

    let(:ret_msg) { instance_double('Cloudenvoy::Message', subscriber: ret_sub) }
    let(:ret_sub) { subscriber }

    before { expect(Cloudenvoy::Message).to receive(:from_descriptor).with(descriptor).and_return(ret_msg) }

    context 'with valid subscriber' do
      let(:resp) { 'some-response' }

      before { expect(ret_sub).to receive(:execute).and_return(resp) }
      it { is_expected.to eq(resp) }
    end

    context 'with invalid subscriber' do
      let(:ret_sub) { nil }

      it { expect { execute }.to raise_error(Cloudenvoy::InvalidSubscriberError) }
    end
  end

  describe '.cloudenvoy_options_hash' do
    subject { subscriber_class.cloudenvoy_options_hash }

    let(:opts) { { foo: 'bar' } }
    let!(:original_opts) { subscriber_class.cloudenvoy_options_hash }

    before { subscriber_class.cloudenvoy_options(opts) }
    after { subscriber_class.cloudenvoy_options(original_opts) }
    it { is_expected.to eq(Hash[opts.map { |k, v| [k.to_sym, v] }]) }
  end

  describe '.topics' do
    subject { subscriber_class.topics }

    let(:topic_list) { ['foo', { name: 'bar', retain_acked: true }] }
    let(:opts_hash) { { topics: topic_list } }
    let(:expected_topics) do
      topic_list.map { |e| e.is_a?(String) ? { name: e } : e }
    end

    before do
      subscriber_class.instance_variable_set('@topics', nil)
      allow(subscriber_class).to receive(:cloudenvoy_options_hash).and_return(opts_hash)
    end

    context 'with topics' do
      it { is_expected.to eq(expected_topics) }
    end

    context 'with topic' do
      let(:opts_hash) { { topic: topic_list } }

      it { is_expected.to eq(expected_topics) }
    end
  end

  describe '.subscription_name' do
    subject { subscriber_class.subscription_name(topic) }

    let(:expected) do
      [
        Cloudenvoy.config.gcp_sub_prefix.tr('.', '-'),
        subscriber_class.to_s.underscore,
        topic
      ].join('.')
    end

    context 'with regular prefix name' do
      it { is_expected.to eq(expected) }
    end

    context 'with dotted prefix' do
      before { allow(Cloudenvoy.config).to receive(:gcp_sub_prefix).and_return('foo.bar') }
      it { is_expected.to eq(expected) }
    end
  end

  describe '.setup' do
    subject { subscriber_class.setup }

    let(:topics) { [{ name: 'foo' }, { name: 'bar', retain_acked: true }] }
    let(:envoy_subs) { Array.new(2) { instance_double('Cloudenvoy::Subscription') } }

    before do
      allow(subscriber_class).to receive(:topics).and_return(topics)
      topics.each_with_index do |t, i|
        expect(Cloudenvoy::PubSubClient).to receive(:upsert_subscription)
          .with(t[:name], subscriber_class.subscription_name(t[:name]), t.reject { |k, _| k.to_sym == :name })
          .and_return(envoy_subs[i])
      end
    end

    it { is_expected.to eq(envoy_subs) }
  end

  describe '.new' do
    subject { subscriber }

    it { is_expected.to have_attributes(message: message) }
  end

  describe '#logger' do
    subject { subscriber.logger }

    it { is_expected.to be_a(Cloudenvoy::SubscriberLogger) }
    it { is_expected.to have_attributes(loggable: subscriber) }
  end

  describe '#process_duration' do
    subject { subscriber.process_duration }

    let(:now) { Time.now }
    let(:process_started_at) { now - 10.0005 }
    let(:process_ended_at) { now }

    before do
      subscriber.process_started_at = process_started_at
      subscriber.process_ended_at = process_ended_at
    end

    context 'with timestamps set' do
      it { is_expected.to eq((process_ended_at - process_started_at).ceil(3)) }
    end

    context 'with no process_started_at' do
      let(:process_started_at) { nil }

      it { is_expected.to eq(0.0) }
    end

    context 'with no process_ended_at' do
      let(:process_ended_at) { nil }

      it { is_expected.to eq(0.0) }
    end
  end

  describe '#execute' do
    subject(:execute) { subscriber.execute }

    let(:args) { [1, 2] }
    let(:resp) { 'some-result' }

    before { allow(subscriber).to receive(:process).with(message).and_return(resp) }
    before { expect(subscriber).to have_attributes(process_started_at: nil, process_ended_at: nil) }
    after { expect(subscriber).to have_attributes(process_started_at: be_a(Time), process_ended_at: be_a(Time)) }

    it { is_expected.to eq(resp) }

    context 'with server middleware chain' do
      before { Cloudenvoy.config.subscriber_middleware.add(TestMiddleware) }
      after { expect(subscriber.middleware_called).to be_truthy }
      it { is_expected.to eq(resp) }
    end

    context 'with runtime error' do
      let(:error) { StandardError.new('some-message') }

      before { allow(subscriber).to receive(:process).and_raise(error) }
      before { expect(subscriber).to receive(:on_error).with(error) }
      it { expect { execute }.to raise_error(error) }
    end
  end

  describe '#==' do
    subject { subscriber }

    it { is_expected.to eq(TestSubscriber.new(message: message)) }
    it { is_expected.not_to eq(TestSubscriber.new(message: 'bar')) }
    it { is_expected.not_to eq('foo') }
  end
end
