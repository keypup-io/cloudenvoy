# frozen_string_literal: true

RSpec.describe Cloudenvoy::Message do
  let(:subscriber_class) { TestSubscriber }
  let(:msg_id) { '1234' }
  let(:payload) { { 'username' => 'john' } }
  let(:metadata) { { 'some' => 'attrs' } }
  let(:topic) { 'foo-topic' }
  let(:sub_uri) { "projects/some-proj/subscriptions/some-app.#{subscriber_class.to_s.underscore}.#{topic}" }

  let(:descriptor_sub) { sub_uri }
  let(:descriptor) do
    {
      'message' => {
        'attributes' => metadata,
        'data' => Base64.strict_encode64(payload.to_json),
        'message_id' => msg_id
      },
      'subscription' => sub_uri
    }
  end

  let(:msg_attrs) do
    {
      id: msg_id,
      metadata: metadata,
      payload: payload,
      sub_uri: sub_uri
    }
  end

  describe '.from_descriptor' do
    subject { described_class.from_descriptor(descriptor) }

    it { is_expected.to have_attributes(msg_attrs.merge(class: described_class)) }
  end

  describe '.new' do
    subject { described_class.new(msg_attrs) }

    it { is_expected.to have_attributes(msg_attrs) }
  end

  describe '#topic' do
    subject { message.topic }

    context 'with no topic specified' do
      let(:message) { described_class.new(msg_attrs) }

      it { is_expected.to eq(topic) }
    end

    context 'with topic specified' do
      let(:msg_topic) { topic + 'aaa' }
      let(:message) { described_class.new(msg_attrs.merge(topic: msg_topic)) }

      it { is_expected.to eq(msg_topic) }
    end

    context 'with no inferrable topic' do
      let(:message) { described_class.new(msg_attrs.except(:sub_uri)) }

      it { is_expected.to be_nil }
    end
  end

  describe '#subscriber' do
    subject { message.subscriber }

    context 'with valid sub_uri' do
      let(:message) { described_class.new(msg_attrs) }

      it { is_expected.to have_attributes(class: TestSubscriber, message: message) }
    end

    context 'with absent sub_uri' do
      let(:message) { described_class.new(msg_attrs.except(:sub_uri)) }

      it { is_expected.to be_nil }
    end
  end

  describe '#==' do
    subject(:message) { described_class.new(msg_attrs) }

    it { is_expected.to eq(described_class.new(id: message.id)) }
    it { is_expected.not_to eq(described_class.new(id: message.id + '111')) }
    it { is_expected.not_to eq('foo') }
  end
end
