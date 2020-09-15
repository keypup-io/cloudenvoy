# frozen_string_literal: true

class HelloSubscriber
  include Cloudenvoy::Subscriber

  cloudenvoy_options topics: ['hello-msgs']

  #
  # Process a pub/sub message
  #
  # @param [Cloudenvoy::Message] message The message to process.
  #
  def process(message)
    logger.info("Received message #{message.payload.dig('content')}")
  end
end
