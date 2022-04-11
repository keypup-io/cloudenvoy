# frozen_string_literal: true

class HelloSubscriber
  include Cloudenvoy::Subscriber

  cloudenvoy_options topic: 'hello-msgs'

  #
  # Process a pub/sub message
  #
  # @param [Cloudenvoy::Message] message The message to process.
  #
  def process(message)
    logger.info("Received message #{message.payload['content']}")
  end
end
