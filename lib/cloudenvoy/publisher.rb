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
      base.attr_accessor :msg_args, :message, :publishing_started_at, :publishing_ended_at

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
    # Publisher can optionally define message attributes (metadata).
    # Message attributes are sent to Pub/Sub and can be used
    # for filtering.
    #
    # @param [Any] *_args The publisher arguments.
    #
    # @return [Hash] The message attributes.
    #
    def metadata(*_args)
      {}
    end

    #
    # Return the Cloudenvoy logger instance.
    #
    # @return [Logger, any] The cloudenvoy logger.
    #
    def logger
      @logger ||= PublisherLogger.new(self)
    end

    #
    # Return the time taken (in seconds) to format and publish the message. This duration
    # includes the middlewares and the actual publish method.
    #
    # @return [Float] The time taken in seconds as a floating point number.
    #
    def publishing_duration
      return 0.0 unless publishing_ended_at && publishing_started_at

      (publishing_ended_at - publishing_started_at).ceil(3)
    end

    #
    # Send the instantiated Publisher (message) to
    # Pub/Sub.
    #
    # @return [Cloudenvoy::Message] The created message.
    #
    def publish
      # Format and publish message
      resp = execute_middleware_chain

      # Log job completion and return result
      logger.info("Published message in #{publishing_duration}s") { { duration: publishing_duration } }
      resp
    rescue StandardError => e
      logger.info("Publishing failed after #{publishing_duration}s") { { duration: publishing_duration } }
      raise(e)
    end

    #=============================
    # Private
    #=============================
    private

    #
    # Internal logic used to build, publish and capture message on the
    # publisher.
    #
    # @return [Cloudenvoy::Message] The published message
    #
    def publish_message
      # Build new message
      self.message = Message.new(
        topic: topic(*msg_args),
        metadata: metadata(*msg_args),
        payload: payload(*msg_args)
      )

      # Publish message to pub/sub
      ps_msg = PubSubClient.publish(
        message.topic,
        message.payload,
        message.metadata
      )
      message.tap { |e| e.id = ps_msg.message_id }
    end

    #
    # Execute the subscriber process method through the middleware chain.
    #
    # @return [Any] The result of the perform method.
    #
    def execute_middleware_chain
      self.publishing_started_at = Time.now

      Cloudenvoy.config.publisher_middleware.invoke(self) do
        begin
          publish_message
        rescue StandardError => e
          try(:on_error, e)
          return raise(e)
        end
      end
    ensure
      self.publishing_ended_at = Time.now
    end
  end
end
