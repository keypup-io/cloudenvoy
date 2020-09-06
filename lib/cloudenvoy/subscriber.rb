# frozen_string_literal: true

module Cloudenvoy
  # Use this module to define subscribers. Subscribers must implement
  # the message processsing logic in the `process` method.
  #
  # E.g.
  #
  # class UserSubscriber
  #   include Cloudenvoy::Subscriber
  #
  #   # Specify subscription options
  #   cloudenvoy_options topics: ['my-topic']
  #
  #   # Process message objects
  #   def process(message, topic, attributes)
  #     ...do something...
  #   end
  # end
  #
  module Subscriber
    # Add class method to including class
    def self.included(base)
      base.attr_accessor :id, :payload, :attributes, :topic, :subscription
    end

    #
    # Execute a subscriber from a payload object received from
    # Pub/Sub.
    #
    # @param [Hash] input_payload The Pub/Sub webhook hash describing
    # the message to process.
    #
    # @return [Any] The subscriber processing return value.
    #
    def self.execute_from_descriptor(input_payload)
      subscriber = from_descriptor(input_payload) || raise(InvalidSubscriberError)
      subscriber.execute
    end

    #
    # Return an instantiated subscriber from a Pub/Sub webhook
    # payload.
    #
    # @param [Hash] input_payload The Pub/Sub webhook hash describing
    # the message to process.
    #
    # @return [Cloudenvoy::Subscriber] The instantiated subscriber
    #
    def self.from_descriptor(input_payload)
      subscription = input_payload['subscription']
      topic, sub_klass_name = subscription.split('/').last(2)

      # Check that subscriber class is a valid subscriber
      sub_klass = Object.const_get(sub_klass_name.camelize)
      return nil unless sub_klass.include?(self)

      # Extract message content
      msg_id = input_payload.dig('message', 'message_id')
      msg_attrs = input_payload.dig('message', 'attributes')
      msg_data = JSON.parse(Base64.decode64(input_payload.dig('message', 'data')))

      # Return the instantiated subscriber
      sub_klass.new(
        id: msg_id,
        payload: msg_data,
        attributes: msg_attrs || {},
        topic: topic,
        subscription: subscription
      )
    rescue NameError
      nil
    end

    #
    # Build a new subscriber instance.
    #
    # @param [String] id Message ID.
    # @param [Hash, String] payload Message content.
    # @param [Hash] attributes Message attributes.
    # @param [String] topic Source topic.
    # @param [String] subscription Source subscription.
    #
    def initialize(id: nil, payload: nil, attributes: {}, topic: nil, subscription: nil)
      @id = id
      @payload = payload
      @attributes = attributes
      @topic = topic
      @subscription = subscription
    end

    #
    # Execute the subscriber's logic.
    #
    # @return [Any] The logic return value
    #
    def execute
      process(payload, attributes, topic, subscription)
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
