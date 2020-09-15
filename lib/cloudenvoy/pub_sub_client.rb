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

      @backend ||= begin
        if defined?(Cloudenvoy::Testing) && Cloudenvoy::Testing.in_memory?
          require 'cloudenvoy/backend/memory_pub_sub'
          Backend::MemoryPubSub
        else
          require 'cloudenvoy/backend/google_pub_sub'
          Backend::GooglePubSub
        end
      end
    end

    #
    # Publish a message to a topic.
    #
    # @param [String] topic The name of the topic
    # @param [Hash, String] payload The message content.
    # @param [Hash] attrs The message attributes.
    #
    # @return [Cloudenvoy::Message] The created message.
    #
    def self.publish(topic, payload, attrs = {})
      backend.publish(topic, payload, attrs)
    end

    #
    # Create or update a subscription for a specific topic.
    #
    # @param [String] topic The name of the topic
    # @param [String] name The name of the subscription
    #
    # @return [Cloudenvoy::Subscription] The upserted subscription.
    #
    def self.upsert_subscription(topic, name)
      backend.upsert_subscription(topic, name)
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
