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
      base.extend(ClassMethods)
      base.attr_accessor :id, :payload, :attributes, :topic, :subscription

      # Register subscriber
      Cloudenvoy.subscribers.add(base)
    end

    #
    # Parse the subscription name and return the subscriber name and topic.
    #
    # @param [String] sub_uri The subscription URI
    #
    # @return [Array<String,String>] A tuple [subscriber_name, topic ]
    #
    def self.parse_subscription(sub_uri)
      sub_uri.split('/').last.split('.').last(2)
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
      sub_klass_name, topic = parse_subscription(subscription)

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

    # Module class methods
    module ClassMethods
      #
      # Set the subscriber runtime options.
      #
      # @param [Hash] opts The subscriber options.
      #
      # @return [Hash] The options set.
      #
      def cloudenvoy_options(opts = {})
        opt_list = opts&.map { |k, v| [k.to_sym, v] } || [] # symbolize
        @cloudenvoy_options_hash = Hash[opt_list]
      end

      #
      # Return the subscriber runtime options.
      #
      # @return [Hash] The subscriber runtime options.
      #
      def cloudenvoy_options_hash
        @cloudenvoy_options_hash || {}
      end

      #
      # Return the list of topics this subscriber listens
      # to.
      #
      # @return [Array<String>] The list of subscribed topics.
      #
      def topics
        cloudenvoy_options_hash[:topics] || []
      end

      #
      # Return the subscription name used by this subscriber
      # to subscribe to a specific topic.
      #
      # @return [String] The subscription name.
      #
      def subscription_name(topic)
        [
          Cloudenvoy.config.gcp_sub_prefix.tr('.', '-'),
          to_s.underscore,
          topic
        ]
      end

      #
      # Create the Subscriber subscription in Pub/Sub.
      #
      # @return [Array<Google::Cloud::PubSub::Subscription>] The upserted subscription.
      #
      def setup
        topics.map do |t|
          PubSubClient.upsert_subscription(t, subscription_name(t))
        end
      end
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
