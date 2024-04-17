# frozen_string_literal: true

RSpec.describe Cloudenvoy::Topic do
  describe '.new' do
    subject { described_class.new(**attrs) }

    let(:attrs) do
      {
        name: 'foo',
        original: instance_double(Google::Cloud::PubSub::Topic)
      }
    end

    it { is_expected.to have_attributes(attrs) }
  end
end
