# frozen_string_literal: true

require 'google/cloud/pubsub'

module Cloudenvoy
  # Interface to GCP Pub/Sub.
  class PubSubClient
    #
    # Return the cloudenvoy configuration. See Cloudenvoy#configure.
    #
    # @return [Cloudenvoy::Config] The library configuration.
    #
    def self.config
      Cloudenvoy.config
    end

    #
    # Return the backend to use for sending messages.
    #
    # @return [Google::Cloud::Pub] The low level client instance.
    #
    def self.backend
      @backend ||= Google::Cloud::PubSub.new(project_id: config.gcp_project_id)
    end

    #
    # Return an authenticated endpoint for processing Pub/Sub webhooks.
    #
    # @return [String] An authenticated endpoint.
    #
    def self.webhook_url
      "#{config.processor_url}?token=#{Authenticator.verification_token}"
    end

    #
    # Publish a message to a topic.
    #
    # @param [String] topic The name of the topic
    # @param [Hash, String] payload The message content.
    # @param [Hash] attrs The message attributes.
    #
    # @return [Google::Cloud::PubSub::Message] The created message.
    #
    def self.publish(topic, payload, attrs = {})
      # Retrieve the topic
      topic = backend.topic(topic, skip_lookup: true)

      # Publish the message
      topic.publish(payload.to_json, attrs.to_h)
    end

    #
    # Create or update a subscription for a specific topic.
    #
    # @param [String] topic The name of the topic
    # @param [String] name The name of the subscription
    #
    # @return [Google::Cloud::PubSub::Subscription] The upserted subscription.
    #
    def self.upsert_subscription(topic, name)
      # Retrieve the topic
      topic = backend.topic(topic, skip_lookup: true)

      # Attempt to create the subscription
      topic.subscribe(name, endpoint: webhook_url)
    rescue Google::Cloud::AlreadyExistsError
      # Update endpoint on subscription
      # Topic is not updated as it is name-dependent
      backend.subscription(name).tap { |e| e.endpoint = webhook_url }
    end

    #
    # Create or update a topic.
    #
    # @param [String] topic The topic name.
    #
    # @return [Google::Cloud::PubSub::Topic] The upserted/topic.
    #
    def self.upsert_topic(topic)
      backend.create_topic(topic)
    rescue Google::Cloud::AlreadyExistsError
      backend.topic(topic)
    end
  end
end
