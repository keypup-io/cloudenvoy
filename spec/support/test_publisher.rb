# frozen_string_literal: true

class TestPublisher
  include Cloudenvoy::Publisher

  cloudenvoy_options topic: 'some-topic'

  def payload(orig_hash)
    {
      foo1: orig_hash[:bar1],
      foo2: orig_hash[:bar2]
    }
  end
end
