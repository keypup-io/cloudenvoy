# frozen_string_literal: true

class HelloPublisher
  include Cloudenvoy::Publisher

  cloudenvoy_options topic: 'hello-msgs'

  #
  # Set message metadata (attributes)
  #
  # @param [String] msg The message to publish
  #
  # @return [Hash] The message metadata
  #
  def metadata(msg)
    {
      kind: msg.start_with?('Hello') ? 'hello' : 'regular'
    }
  end

  #
  # Format the payload.
  #
  # @param [String] msg The message to publish
  #
  # @return [Hash] The formatted message
  #
  def payload(msg)
    {
      type: 'message',
      content: msg
    }
  end
end
