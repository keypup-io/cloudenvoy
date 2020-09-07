# frozen_string_literal: true

module Cloudenvoy
  # Use this module to define publishers. The module provides
  # a simple DSL for transforming and publishing data objects to
  # Pub/Sub.
  #
  # Publishers must at least implement the `payload` method, which defines
  # how arguments are mapped to a Hash or String message.
  #
  # E.g.
  #
  # class UserPublisher
  #   include Cloudenvoy::Publisher
  #
  #   # Specify publishing options
  #   cloudenvoy_options topic: 'my-topic'
  #
  #   # Format message objects
  #   def payload(user)
  #     {
  #       id: user.id,
  #       name: user.name
  #     }
  #   end
  # end
  #
  module Publisher
    # Add class method to including class
    def self.included(base)
      base.extend(ClassMethods)
      base.attr_accessor :msg_args

      # Register subscriber
      Cloudenvoy.publishers.add(base)
    end

    # Module class methods
    module ClassMethods
      #
      # Set the publisher runtime options.
      #
      # @param [Hash] opts The publisher options.
      #
      # @return [Hash] The options set.
      #
      def cloudenvoy_options(opts = {})
        opt_list = opts&.map { |k, v| [k.to_sym, v] } || [] # symbolize
        @cloudenvoy_options_hash = Hash[opt_list]
      end

      #
      # Return the publisher runtime options.
      #
      # @return [Hash] The publisher runtime options.
      #
      def cloudenvoy_options_hash
        @cloudenvoy_options_hash || {}
      end

      #
      # Return the default topic this publisher publishes to.
      # Raises an error if no default topic has been defined.
      #
      # @return [String] The default topic.
      #
      def default_topic
        cloudenvoy_options_hash[:topic]
      end

      #
      # Format and publish objects to Pub/Sub.
      #
      # @param [Any] *args The publisher arguments
      #
      # @return [Google::Cloud::PubSub::Message] The created message.
      #
      def publish(*args)
        new(msg_args: args).publish
      end

      #
      # Setup the default topic for this publisher.
      #
      # @return [Google::Cloud::PubSub::Topic] The upserted/topic.
      #
      def setup
        return nil unless default_topic

        PubSubClient.upsert_topic(default_topic)
      end
    end

    #
    # Build a new publisher instance.
    #
    # @param [Array<any>] msg_args The list of payload args.
    #
    def initialize(msg_args: nil)
      @msg_args = msg_args || []
    end

    #
    # Return the topic to publish to. The topic name
    # can be dynamically evaluated at runtime based on
    # publishing arguments.
    #
    # Defaults to the topic specified via cloudenvoy_options.
    #
    # @param [Any] *_args The publisher arguments.
    #
    # @return [String] The topic name.
    #
    def topic(*_args)
      self.class.default_topic
    end

    #
    # Publisher can optionally define message attributes.
    # Message attributes are sent to Pub/Sub and can be used
    # for filtering.
    #
    # @param [Any] *_args The publisher arguments.
    #
    # @return [Hash] The message attributes.
    #
    def attributes(*_args)
      {}
    end

    #
    # Send the instantiated Publisher (message) to
    # Pub/Sub.
    #
    # @return [Google::Cloud::PubSub::Message] The created message.
    #
    def publish
      PubSubClient.publish(
        topic(*msg_args),
        payload(*msg_args),
        attributes(*msg_args)
      )
    end
  end
end
