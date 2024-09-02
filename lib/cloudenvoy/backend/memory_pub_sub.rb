# frozen_string_literal: true

require 'google/cloud/pubsub'

module Cloudenvoy
  module Backend
    # Store messages in a memory queue. Used for testing
    module MemoryPubSub
      module_function

      #
      # Return the message queue for a specific topic.
      #
      # @param [String] name The topic to retrieve.
      #
      # @return [Array] The list of messages for the provided topic
      #
      def queue(topic)
        @queues ||= {}
        @queues[topic.to_s] ||= []
      end

      #
      # Clear all messages in a specific topic.
      #
      # @param [String] name The topic to clear.
      #
      # @return [Array] The cleared array.
      #
      def clear(topic)
        queue(topic).clear
      end

      #
      # Clear all messages across all topics.
      #
      # @param [String] name The topic to clear.
      #
      def clear_all
        @queues&.each_value(&:clear)
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
      def publish(topic, payload, metadata = {})
        msg = Message.new(
          id: SecureRandom.uuid,
          payload: payload,
          metadata: metadata,
          topic: topic
        )
        queue(topic).push(msg)

        msg
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
        # Build the messages
        msgs = msg_args.map do |(payload, metadata)|
          Message.new(
            id: SecureRandom.uuid,
            payload: payload,
            metadata: metadata,
            topic: topic
          )
        end

        # Push all the messages and return them
        queue(topic).push(*msgs)
        msgs
      end

      #
      # Create or update a subscription for a specific topic.
      #
      # @param [String] topic The name of the topic
      # @param [String] name The name of the subscription
      # @param [Hash] opts The subscription configuration options
      #
      # @return [Cloudenvoy::Subscription] The upserted subscription.
      #
      def upsert_subscription(_topic, name, _opts)
        Subscription.new(name: name)
      end

      #
      # Create or update a topic.
      #
      # @param [String] topic The topic name.
      #
      # @return [Cloudenvoy::Topic] The upserted topic.
      #
      def upsert_topic(topic)
        Topic.new(name: topic)
      end
    end
  end
end
