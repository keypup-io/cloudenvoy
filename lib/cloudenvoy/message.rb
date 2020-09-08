# frozen_string_literal: true

module Cloudenvoy
  # Represents a Pub/Sub message
  class Message
    attr_writer :topic
    attr_accessor :id, :payload, :metadata, :sub_uri

    #
    # Return an instantiated message from a Pub/Sub webhook
    # payload.
    #
    # @param [Hash] input_payload The Pub/Sub webhook hash describing
    # the message to process.
    #
    # @return [Cloudenvoy::Message] The instantiated message.
    #
    def self.from_descriptor(input_payload)
      # Build new message
      new(
        id: input_payload.dig('message', 'message_id'),
        payload: JSON.parse(Base64.decode64(input_payload.dig('message', 'data'))),
        metadata: input_payload.dig('message', 'attributes'),
        sub_uri: input_payload['subscription']
      )
    end

    #
    # Constructor
    #
    # @param [String] id The message ID
    # @param [Hash, String] payload The message payload
    # @param [Hash] metadata The message attributes
    # @param [String] topic The topic - will be inferred from sub_uri if left blank
    # @param [String] sub_uri The sub_uri this message was sent for
    #
    def initialize(id: nil, payload: nil, metadata: nil, topic: nil, sub_uri: nil)
      @id = id
      @payload = payload
      @topic = topic
      @metadata = metadata || {}
      @sub_uri = sub_uri
    end

    #
    # Return the message topic.
    #
    # @return [String] The message topic.
    #
    def topic
      return @topic if @topic
      return nil unless sub_uri

      Subscriber.parse_sub_uri(sub_uri)[1]
    end

    #
    # Return the instantiated Subscriber designated to process this message.
    #
    # @return [Subscriber] The instantiated subscriber.
    #
    def subscriber
      @subscriber ||= begin
        return nil unless sub_uri && (klass = Subscriber.from_sub_uri(sub_uri))

        klass.new(message: self)
      end
    end

    #
    # Return a hash description of the message.
    #
    # @return [Hash] The message description
    #
    def to_h
      {
        id: id,
        payload: payload,
        metadata: metadata,
        topic: topic,
        sub_uri: sub_uri
      }.compact
    end

    #
    # Equality operator.
    #
    # @param [Any] other The object to compare.
    #
    # @return [Boolean] True if the object is equal.
    #
    def ==(other)
      other.is_a?(self.class) && other.id == id
    end
  end
end
