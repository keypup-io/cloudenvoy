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
  end
end
