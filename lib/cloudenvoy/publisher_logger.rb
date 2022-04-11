# frozen_string_literal: true

module Cloudenvoy
  # Logger configuration for publishers
  class PublisherLogger < LoggerWrapper
    #
    # The subscriber default context processor.
    #
    # @return [Proc] The context processor proc.
    #
    def self.default_context_processor
      @default_context_processor ||= ->(loggable) { loggable.message.to_h&.slice(:id, :metadata, :topic) || {} }
    end

    #
    # Format main log message.
    #
    # @param [String] msg The message to log.
    #
    # @return [String] The formatted log message
    #
    def formatted_message(msg)
      [
        '[Cloudenvoy]',
        "[#{loggable.class}]",
        loggable.message&.id ? "[#{loggable.message.id}]" : nil,
        ' ',
        msg
      ].compact.join
    end
  end
end
