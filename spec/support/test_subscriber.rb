# frozen_string_literal: true

class TestSubscriber
  attr_accessor :username
  include Cloudenvoy::Subscriber

  def process(payload, _attributes, _topic, _subscription)
    @username = payload['username']
  end
end
