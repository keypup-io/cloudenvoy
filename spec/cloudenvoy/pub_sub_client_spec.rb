# frozen_string_literal: true

RSpec.describe Cloudenvoy::PubSubClient do
  let(:gcp_project_id) { Cloudenvoy.config.gcp_project_id }
  let(:backend) { instance_double('Google::Cloud::PubSub::Project') }

  describe '.config' do
    subject { described_class.config }

    it { is_expected.to eq(Cloudenvoy.config) }
  end

  describe '.backend' do
    subject { described_class.backend }

    before { allow(Google::Cloud::PubSub).to receive(:new).with(project_id: gcp_project_id).and_return(backend) }
    it { is_expected.to eq(backend) }
  end

  describe '.publish' do
    subject { described_class.publish(topic, payload, msg_attrs) }

    let(:topic) { 'some-topic' }
    let(:payload) { { foo: 'bar' } }
    let(:msg_attrs) { { some: 'attribute' } }
    let(:gcp_topic) { instance_double('Google::Cloud::PubSub::Topic') }
    let(:gcp_msg) { instance_double('Google::Cloud::PubSub::Message') }

    before do
      expect(described_class).to receive(:backend).and_return(backend)
      expect(backend).to receive(:topic).with(topic, skip_lookup: true).and_return(gcp_topic)
      expect(gcp_topic).to receive(:publish).with(payload.to_json, msg_attrs).and_return(gcp_msg)
    end

    it { is_expected.to eq(gcp_msg) }
  end
end
