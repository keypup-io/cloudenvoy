# frozen_string_literal: true

RSpec.describe Cloudenvoy::Publisher do
  let(:publisher_class) { TestPublisher }
  let(:msg_args) { [{ foo: 'bar' }] }
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

  describe '.publish_all' do
    subject { publisher_class.publish_all(arg_list) }

    let(:arg_list) { [{ bar1: '1' }, { bar1: '2' }] }
    let(:expected_ret) do
      arg_list.map do |args|
        msg_args = [args].flatten(1)
        publisher = publisher_class.new(msg_args: msg_args)

        {
          class: Cloudenvoy::Message,
          topic: publisher.topic(*msg_args),
          payload: publisher.payload(*msg_args),
          metadata: publisher.metadata(*msg_args)
        }
      end
    end

    around { |e| Cloudenvoy::Testing.fake! { e.run } }

    context 'with all messages to the same topic' do
      let(:topic) { publisher_class.default_topic }
      let(:queue) { Cloudenvoy::Testing.queue(topic) }

      before { expect(Cloudenvoy::PubSubClient).to receive(:publish_all).with(topic, expected_ret.map { |e| [e[:payload], e[:metadata]] }).and_call_original }
      after { expect(queue).to match(expected_ret.map { |e| have_attributes(e) }) }

      it { is_expected.to match(expected_ret.map { |e| have_attributes(e) }) }
    end

    context 'with publisher middleware' do
      let(:topic) { publisher_class.default_topic }
      let(:queue) { Cloudenvoy::Testing.queue(topic) }

      let(:modified_ret) { expected_ret.map { |e| e.merge(payload: e[:payload].merge(_middleware_called: true)) } }

      before { Cloudenvoy.config.publisher_middleware.add(ArgModifyingMiddleware) }
      before { expect(Cloudenvoy::PubSubClient).to receive(:publish_all).with(topic, modified_ret.map { |e| [e[:payload], e[:metadata]] }).and_call_original }
      after { expect(queue).to match(modified_ret.map { |e| have_attributes(e) }) }

      it { is_expected.to match(modified_ret.map { |e| have_attributes(e) }) }
    end

    context 'with multiple topics' do
      let(:arg_list) { [{ bar1: '1.1', _topic: topic1 }, { bar1: '1.2', _topic: topic1 }, { bar1: '2.1', _topic: topic2 }] }

      let(:topic1) { 'topic1' }
      let(:topic2) { 'topic2' }
      let(:queue1) { Cloudenvoy::Testing.queue(topic1) }
      let(:queue2) { Cloudenvoy::Testing.queue(topic2) }

      let(:topic1_msgs) { expected_ret.select { |e| e[:topic] == topic1 } }
      let(:topic2_msgs) { expected_ret.select { |e| e[:topic] == topic2 } }

      before do
        expect(Cloudenvoy::PubSubClient).to receive(:publish_all).with(topic1, topic1_msgs.map { |e| [e[:payload], e[:metadata]] }).and_call_original
        expect(Cloudenvoy::PubSubClient).to receive(:publish_all).with(topic2, topic2_msgs.map { |e| [e[:payload], e[:metadata]] }).and_call_original
      end
      after do
        expect(queue1).to match(topic1_msgs.map { |e| have_attributes(e) })
        expect(queue2).to match(topic2_msgs.map { |e| have_attributes(e) })
      end

      it { is_expected.to match(expected_ret.map { |e| have_attributes(e) }) }
    end
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

    context 'with publisher middleware' do
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
