# frozen_string_literal: true

module Cloudenvoy
  # Interface to publishing backend (GCP, emulator or memory backend)
  class PubSubClient
    #
    # Return the backend to use for sending messages.
    #
    # @return [Module<Cloudenvoy::Backend::MemoryPubSub, Cloudenvoy::Backend::GoogleCloudTask>] The backend class.
    #
    def self.backend
      # Re-evaluate backend every time if testing mode enabled
      @backend = nil if defined?(Cloudenvoy::Testing)

      @backend ||= if defined?(Cloudenvoy::Testing) && Cloudenvoy::Testing.in_memory?
                     require 'cloudenvoy/backend/memory_pub_sub'
                     Backend::MemoryPubSub
                   else
                     require 'cloudenvoy/backend/google_pub_sub'
                     Backend::GooglePubSub
                   end
    end

    #
    # Publish a message to a topic.
    #
    # @param [String] topic The name of the topic
    # @param [Hash, String] payload The message content.
    # @param [Hash] attrs The message attributes.
    #
    # @return [Cloudenvoy::Message] The published message.
    #
    def self.publish(topic, payload, attrs = {})
      backend.publish(topic, payload, attrs)
    end

    #
    # Publish multiple messages to a topic.
    #
    # @param [String] topic The name of the topic
    # @param [Array<Array<[Hash, String]>>] msg_args A list of message [payload, metadata].
    #
    # @return [Array<Cloudenvoy::Message>] The published messages.
    #
    def self.publish_all(topic, msg_args)
      msg_args.each_slice(Config::BATCH_MAX_MSG_COUNT).flat_map do |args_batch|
        backend.publish_all(topic, args_batch)
      end
    end

    #
    # Create or update a subscription for a specific topic.
    #
    # @param [String] topic The name of the topic
    # @param [String] name The name of the subscription
    # @param [Hash] opts The subscription configuration options
    # @option opts [Integer] :deadline The maximum number of seconds after a subscriber receives a message
    #   before the subscriber should acknowledge the message.
    # @option opts [Boolean] :retain_acked Indicates whether to retain acknowledged messages. If true,
    #   then messages are not expunged from the subscription's backlog, even if they are acknowledged,
    #   until they fall out of the retention window. Default is false.
    # @option opts [<Type>] :retention How long to retain unacknowledged messages in the subscription's
    #   backlog, from the moment a message is published. If retain_acked is true, then this also configures
    #   the retention of acknowledged messages, and thus configures how far back in time a Subscription#seek
    #   can be done. Cannot be more than 604,800 seconds (7 days) or less than 600 seconds (10 minutes).
    #   Default is 604,800 seconds (7 days).
    # @option opts [String] :filter An expression written in the Cloud Pub/Sub filter language.
    #   If non-empty, then only Message instances whose attributes field matches the filter are delivered
    #   on this subscription. If empty, then no messages are filtered out. Optional.
    #
    # @return [Cloudenvoy::Subscription] The upserted subscription.
    #
    def self.upsert_subscription(topic, name, opts = {})
      backend.upsert_subscription(topic, name, opts)
    end

    #
    # Create or update a topic.
    #
    # @param [String] topic The topic name.
    #
    # @return [Cloudenvoy::Topic] The upserted/topic.
    #
    def self.upsert_topic(topic)
      backend.upsert_topic(topic)
    end
  end
end
