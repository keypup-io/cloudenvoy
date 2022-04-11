# frozen_string_literal: true

class TestPublisher
  include Cloudenvoy::Publisher
  attr_accessor :middleware_called

  cloudenvoy_options topic: 'some-topic'

  def payload(hash)
    {
      foo1: hash[:bar1],
      foo2: hash[:bar2],
      _middleware_called: hash[:_middleware_called]
    }.compact
  end

  def topic(hash)
    hash[:_topic] || self.class.default_topic
  end
end
