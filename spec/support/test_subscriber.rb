# frozen_string_literal: true

class TestSubscriber
  attr_accessor :username
  include Cloudenvoy::Subscriber

  cloudenvoy_options topics: ['some-topic']

  def process(message)
    @username = message.payload['username']
  end
end
