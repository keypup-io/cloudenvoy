# frozen_string_literal: true

RSpec.describe Cloudenvoy::Subscription do
  describe '.new' do
    subject { described_class.new(**attrs) }

    let(:attrs) do
      {
        name: 'foo',
        original: instance_double('Google::Cloud::PubSub::Subscription')
      }
    end

    it { is_expected.to have_attributes(attrs) }
  end
end
