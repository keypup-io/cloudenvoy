# frozen_string_literal: true

RSpec.describe Cloudenvoy::PubSubClient do
  let(:gcp_project_id) { Cloudenvoy.config.gcp_project_id }
  let(:backend) { instance_double('Google::Cloud::PubSub::Project') }
  let(:gcp_topic) { instance_double('Google::Cloud::PubSub::Topic') }

  describe '.config' do
    subject { described_class.config }

    it { is_expected.to eq(Cloudenvoy.config) }
  end

  describe '.backend' do
    subject { described_class.backend }

    before { allow(Google::Cloud::PubSub).to receive(:new).with(project_id: gcp_project_id).and_return(backend) }
    it { is_expected.to eq(backend) }
  end

  describe '.webhook_url' do
    subject { described_class.webhook_url }

    let(:token) { '123' }

    before { allow(Cloudenvoy::Authenticator).to receive(:verification_token).and_return(token) }
    it { is_expected.to eq("#{described_class.config.processor_url}?token=#{token}") }
  end

  describe '.publish' do
    subject { described_class.publish(topic, payload, msg_attrs) }

    let(:topic) { 'some-topic' }
    let(:payload) { { foo: 'bar' } }
    let(:msg_attrs) { { some: 'attribute' } }
    let(:gcp_msg) { instance_double('Google::Cloud::PubSub::Message') }

    before do
      expect(described_class).to receive(:backend).and_return(backend)
      expect(backend).to receive(:topic).with(topic, skip_lookup: true).and_return(gcp_topic)
      expect(gcp_topic).to receive(:publish).with(payload.to_json, msg_attrs).and_return(gcp_msg)
    end

    it { is_expected.to eq(gcp_msg) }
  end

  describe '.upsert_subscription' do
    subject { described_class.upsert_subscription(topic, sub_name) }

    let(:topic) { 'some-topic' }
    let(:sub_name) { 'some.name' }
    let(:webhook_url) { "#{described_class.config.processor_url}?token=123" }
    let(:gcp_sub) { instance_double('Google::Cloud::PubSub::Subscription') }

    before do
      allow(described_class).to receive(:backend).and_return(backend)
      allow(backend).to receive(:topic).with(topic, skip_lookup: true).and_return(gcp_topic)
      allow(described_class).to receive(:webhook_url).and_return(webhook_url)
    end

    context 'with non-existing subscription' do
      before { expect(gcp_topic).to receive(:subscribe).with(sub_name, endpoint: webhook_url).and_return(gcp_sub) }
      it { is_expected.to eq(gcp_sub) }
    end

    context 'with existing subscription' do
      before do
        expect(gcp_topic).to receive(:subscribe)
          .with(sub_name, endpoint: webhook_url)
          .and_raise(Google::Cloud::AlreadyExistsError)
        expect(backend).to receive(:subscription).with(sub_name).and_return(gcp_sub)
        expect(gcp_sub).to receive(:endpoint=).with(webhook_url)
      end

      it { is_expected.to eq(gcp_sub) }
    end
  end

  describe '.upsert_topic' do
    subject { described_class.upsert_topic(topic) }

    let(:topic) { 'some-topic' }
    let(:gcp_topic) { instance_double('Google::Cloud::PubSub::Topic') }

    before { allow(described_class).to receive(:backend).and_return(backend) }

    context 'with non-existing topic' do
      before { expect(backend).to receive(:create_topic).with(topic).and_return(gcp_topic) }
      it { is_expected.to eq(gcp_topic) }
    end

    context 'with existing topic' do
      before do
        expect(backend).to receive(:create_topic).with(topic).and_raise(Google::Cloud::AlreadyExistsError)
        expect(backend).to receive(:topic).with(topic).and_return(gcp_topic)
      end

      it { is_expected.to eq(gcp_topic) }
    end
  end
end