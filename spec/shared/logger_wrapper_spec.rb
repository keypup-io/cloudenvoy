# frozen_string_literal: true

RSpec.shared_examples 'a log appender' do |level|
  subject(:log_action) { logger.send(level, msg, &block) }

  let(:msg) { 'Some message' }
  let(:block) { nil }
  let(:log_msg) { logger.formatted_message(msg) }
  let(:log_block) { logger.log_block }

  context 'without block' do
    before do
      allow(Cloudenvoy.logger).to receive(level) do |args, &arg_block|
        expect(args).to eq(log_msg)
        expect(arg_block.call).to eq(log_block.call)
      end
    end
    after { expect(Cloudenvoy.logger).to have_received(level) }
    it { is_expected.to be_truthy }
  end

  context 'with block' do
    let(:block) { proc { { foo: 'bar' } } }

    before do
      allow(Cloudenvoy.logger).to receive(level) do |args, &arg_block|
        expect(args).to eq(log_msg)
        expect(arg_block.call).to eq(log_block.call.merge(block.call))
      end
    end
    after { expect(Cloudenvoy.logger).to have_received(level) }
    it { is_expected.to be_truthy }
  end

  context 'with ActiveSupport::Logger' do
    let(:as_logger) { ActiveSupport::Logger.new(nil) }

    before do
      allow(logger).to receive(:logger).and_return(as_logger)
      allow(as_logger).to receive(level) do |*_args, &block|
        expect(block.call).to eq("#{log_msg} -- #{log_block.call}")
      end
    end
    after { expect(as_logger).to have_received(level) }
    it { is_expected.to be_truthy }
  end

  describe 'end to end' do
    let(:block) { proc { { foo: 'bar' } } }

    before { allow(logger).to receive(:logger).and_return(logger_adapter) }

    context 'with Logger' do
      let(:logger_adapter) { Logger.new(nil) }

      it { expect { log_action }.not_to raise_error }
    end

    context 'with ActiveSupport::Logger' do
      let(:logger_adapter) { ActiveSupport::Logger.new(nil) }

      it { expect { log_action }.not_to raise_error }
    end

    context 'with SemanticLogger' do
      let(:logger_adapter) { SemanticLogger[Cloudenvoy] }
      let(:block) { -> { { foo: 'bar' } } }

      it { expect { log_action }.not_to raise_error }
    end
  end
end

# Requires:
#
# let(:loggable) { SomeLoggableClass.new }
#
RSpec.shared_examples Cloudenvoy::LoggerWrapper do
  let(:logger) { described_class.new(loggable) }
  let(:loggable) { TestPublisher.new }

  describe '.new' do
    subject { logger }

    it { is_expected.to have_attributes(loggable: loggable) }
  end

  describe '#context_processor' do
    subject { logger.context_processor }

    let(:processor) { lambda(&:to_h) }

    context 'with no context_processor defined' do
      it { is_expected.to eq(described_class.default_context_processor) }
    end

    context 'with globally defined context_processor' do
      before { allow(described_class).to receive(:log_context_processor).and_return(processor) }
      it { is_expected.to eq(processor) }
    end

    context 'with locally defined context_processor' do
      let(:options) { { log_context_processor: processor } }

      before { allow(loggable.class).to receive(:cloudenvoy_options_hash).and_return(options) }
      it { is_expected.to eq(processor) }
    end
  end

  describe '#log_block' do
    subject { logger.log_block.call }

    it { is_expected.to eq(logger.context_processor.call(loggable)) }
  end

  describe '#logger' do
    subject { logger.logger }

    it { is_expected.to eq(Cloudenvoy.logger) }
  end

  # Skip if method has been overriden by child logger
  unless described_class.instance_method(:formatted_message).owner == described_class
    describe '#formatted_message' do
      subject { logger.formatted_message(msg) }

      let(:msg) { 'some message' }

      it { is_expected.to eq("[Cloudenvoy][#{loggable.class}] #{msg}") }
    end
  end

  describe '#info' do
    it_behaves_like 'a log appender', :info
  end

  describe '#error' do
    it_behaves_like 'a log appender', :error
  end

  describe '#fatal' do
    it_behaves_like 'a log appender', :fatal
  end

  describe '#debug' do
    it_behaves_like 'a log appender', :debug
  end

  describe 'other method' do
    subject { logger.info? }

    before { allow(Cloudenvoy.logger).to receive(:info?).and_return(true) }
    after { expect(Cloudenvoy.logger).to have_received(:info?) }
    it { is_expected.to be_truthy }
  end
end
