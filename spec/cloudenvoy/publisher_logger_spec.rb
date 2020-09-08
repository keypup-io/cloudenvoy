# frozen_string_literal: true

RSpec.describe Cloudenvoy::PublisherLogger do
  let(:message) do
    Cloudenvoy::Message.new(
      id: '123',
      metadata: { 'some' => 'attribute' },
      payload: { 'foo' => 'bar' },
      topic: 'my-topic'
    )
  end
  let(:publisher) { TestPublisher.new.tap { |e| e.message = message } }
  let(:logger) { described_class.new(publisher) }

  it_behaves_like Cloudenvoy::LoggerWrapper do
    let(:loggable) { TestPublisher.new }
  end

  describe '.default_context_processor' do
    subject { described_class.default_context_processor.call(publisher) }

    context 'with message' do
      it { is_expected.to eq(publisher.message.to_h.slice(:id, :metadata, :topic)) }
    end

    context 'with no message' do
      let(:message) { nil }

      it { is_expected.to eq({}) }
    end
  end

  describe '#formatted_message' do
    subject { logger.formatted_message(msg) }

    let(:msg) { 'some message' }

    context 'with message' do
      it { is_expected.to eq("[Cloudenvoy][#{publisher.class}][#{message.id}] #{msg}") }
    end

    context 'with no message' do
      let(:message) { nil }

      it { is_expected.to eq("[Cloudenvoy][#{publisher.class}] #{msg}") }
    end
  end
end
