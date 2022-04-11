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
      # Return true if the current config mode is development.
      #
      # @return [Boolean] True if Cloudenvoy is run in development mode.
      #
      def development?
        config.mode == :development
      end

      #
      # Return the backend to use for sending messages.
      #
      # @return [Google::Cloud::Pub] The low level client instance.
      #
      def backend
        @backend ||= Google::Cloud::PubSub.new(**{
          project_id: config.gcp_project_id,
          emulator_host: development? ? Cloudenvoy::Config::EMULATOR_HOST : nil
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
      # @return [Cloudenvoy::Message] The published message.
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
      # Publish multiple messages to a topic.
      #
      # @param [String] topic The name of the topic
      # @param [Array<Array<[Hash, String]>>] msg_args A list of message [payload, metadata].
      #
      # @return [Array<Cloudenvoy::Message>] The published messages.
      #
      def publish_all(topic, msg_args)
        # Retrieve the topic
        ps_topic = backend.topic(topic, skip_lookup: true)

        # Publish the message
        ps_msgs = ps_topic.publish do |batch|
          msg_args.each do |(payload, metadata)|
            batch.publish(payload.to_json, metadata.to_h)
          end
        end

        # Return the formatted messages
        ps_msgs.each_with_index.map do |ps_msg, index|
          payload, metadata = msg_args[index]

          Message.new(
            id: ps_msg.message_id,
            payload: payload,
            metadata: metadata,
            topic: topic
          )
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
      def upsert_subscription(topic, name, opts = {})
        sub_config = opts.to_h.merge(endpoint: webhook_url)

        # Auto-create topic in development. In non-development environments
        # the create subscription action raises an error if the topic does
        # not exist
        upsert_topic(topic) if development?

        # Create subscription
        ps_sub =
          begin
            # Retrieve the topic
            ps_topic = backend.topic(topic, skip_lookup: true)

            # Attempt to create the subscription
            ps_topic.subscribe(name, **sub_config)
          rescue Google::Cloud::AlreadyExistsError
            # Update endpoint on subscription
            # Topic is not updated as it is name-dependent
            backend.subscription(name).tap do |e|
              sub_config.each do |k, v|
                e.send("#{k}=", v)
              end
            end
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
