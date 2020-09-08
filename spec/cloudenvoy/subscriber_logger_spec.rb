# frozen_string_literal: true

RSpec.describe Cloudenvoy::SubscriberLogger do
  let(:message) do
    Cloudenvoy::Message.new(
      id: '123',
      metadata: { 'some' => 'attribute' },
      payload: { 'foo' => 'bar' },
      topic: 'my-topic'
    )
  end
  let(:subscriber) { TestSubscriber.new(message: message) }
  let(:logger) { described_class.new(subscriber) }

  it_behaves_like Cloudenvoy::LoggerWrapper do
    let(:loggable) { subscriber }
  end

  describe '.default_context_processor' do
    subject { described_class.default_context_processor.call(subscriber) }

    it { is_expected.to eq(subscriber.message.to_h.slice(:id, :metadata, :topic)) }
  end

  describe '#formatted_message' do
    subject { logger.formatted_message(msg) }

    let(:msg) { 'some message' }

    it { is_expected.to eq("[Cloudenvoy][#{subscriber.class}][#{message.id}] #{msg}") }
  end
end
