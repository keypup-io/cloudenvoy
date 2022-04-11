# frozen_string_literal: true

RSpec.describe Cloudenvoy::Testing do
  let(:topic) { 'some-topic' }
  let(:payload) { { bar1: 'foo1', bar2: 'foo2' } }

  before { Cloudenvoy::Backend::MemoryPubSub.clear_all }
  after { described_class.enable! }

  describe '.fake!' do
    subject { Cloudenvoy::Backend::MemoryPubSub.queue(topic) }

    context 'with option set' do
      before { described_class.fake! }
      before { TestPublisher.publish(payload) }
      it { is_expected.to match([be_a(Cloudenvoy::Message)]) }
    end

    context 'with block' do
      around do |e|
        described_class.fake! { e.run }
        expect(described_class).to be_enabled
      end
      before { TestPublisher.publish(payload) }
      it { is_expected.to match([be_a(Cloudenvoy::Message)]) }
    end
  end

  describe '.clear_all' do
    subject { described_class.clear_all }

    let(:ret) { instance_double('Array') }

    before { expect(Cloudenvoy::Backend::MemoryPubSub).to receive(:clear_all).and_return(ret) }
    it { is_expected.to eq(ret) }
  end

  describe '.clear' do
    subject { described_class.clear(topic) }

    let(:topic) { 'foo' }
    let(:ret) { instance_double('Array') }

    before { expect(Cloudenvoy::Backend::MemoryPubSub).to receive(:clear).with(topic).and_return(ret) }
    it { is_expected.to eq(ret) }
  end

  describe '.queue' do
    subject { described_class.queue(topic) }

    let(:topic) { 'foo' }
    let(:ret) { instance_double('Array') }

    before { expect(Cloudenvoy::Backend::MemoryPubSub).to receive(:queue).with(topic).and_return(ret) }
    it { is_expected.to eq(ret) }
  end
end
