# frozen_string_literal: true

class TestSubscriber
  include Cloudenvoy::Subscriber
  attr_accessor :username, :middleware_called, :middleware_opts

  cloudenvoy_options topics: ['some-topic']

  def process(message)
    @username = message.payload['username']
  end
end
