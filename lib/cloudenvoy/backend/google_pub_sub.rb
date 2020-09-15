# frozen_string_literal: true

require 'google/cloud/pubsub'

module Cloudenvoy
  module Backend
    # Interface to GCP Pub/Sub and Pub/Sub local emulator
    module GooglePubSub
      module_function

      #
      # Return the cloudenvoy configuration. See Cloudenvoy#configure.
      #
      # @return [Cloudenvoy::Config] The library configuration.
      #
      def config
        Cloudenvoy.config
      end

      #
      # Return the backend to use for sending messages.
      #
      # @return [Google::Cloud::Pub] The low level client instance.
      #
      def backend
        @backend ||= Google::Cloud::PubSub.new({
          project_id: config.gcp_project_id,
          emulator_host: config.mode == :development ? Cloudenvoy::Config::EMULATOR_HOST : nil
        }.compact)
      end

      #
      # Return an authenticated endpoint for processing Pub/Sub webhooks.
      #
      # @return [String] An authenticated endpoint.
      #
      def webhook_url
        "#{config.processor_url}?token=#{Authenticator.verification_token}"
      end

      #
      # Publish a message to a topic.
      #
      # @param [String] topic The name of the topic
      # @param [Hash, String] payload The message content.
      # @param [Hash] metadata The message attributes.
      #
      # @return [Cloudenvoy::Message] The created message.
      #
      def publish(topic, payload, metadata = {})
        # Retrieve the topic
        ps_topic = backend.topic(topic, skip_lookup: true)

        # Publish the message
        ps_msg = ps_topic.publish(payload.to_json, metadata.to_h)

        # Return formatted message
        Message.new(
          id: ps_msg.message_id,
          payload: payload,
          metadata: metadata,
          topic: topic
        )
      end

      #
      # Create or update a subscription for a specific topic.
      #
      # @param [String] topic The name of the topic
      # @param [String] name The name of the subscription
      #
      # @return [Cloudenvoy::Subscription] The upserted subscription.
      #
      def upsert_subscription(topic, name)
        ps_sub = begin
          # Retrieve the topic
          ps_topic = backend.topic(topic, skip_lookup: true)

          # Attempt to create the subscription
          ps_topic.subscribe(name, endpoint: webhook_url)
                 rescue Google::Cloud::AlreadyExistsError
                   # Update endpoint on subscription
                   # Topic is not updated as it is name-dependent
                   backend.subscription(name).tap { |e| e.endpoint = webhook_url }
        end

        # Return formatted subscription
        Subscription.new(name: ps_sub.name, original: ps_sub)
      end

      #
      # Create or update a topic.
      #
      # @param [String] topic The topic name.
      #
      # @return [Cloudenvoy::Topic] The upserted topic.
      #
      def upsert_topic(topic)
        ps_topic = begin
          backend.create_topic(topic)
                   rescue Google::Cloud::AlreadyExistsError
                     backend.topic(topic)
        end

        # Return formatted subscription
        Topic.new(name: ps_topic.name, original: ps_topic)
      end
    end
  end
end
