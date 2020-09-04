# frozen_string_literal: true

RSpec.describe Cloudenvoy do
  describe '::VERSION' do
    subject { Cloudenvoy::VERSION }

    it { is_expected.not_to be nil }
  end
end
