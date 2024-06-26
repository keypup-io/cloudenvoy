# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'

require 'cloudenvoy/version'
require 'cloudenvoy/config'

require 'cloudenvoy/authentication_error'
require 'cloudenvoy/invalid_subscriber_error'

require 'cloudenvoy/middleware/chain'
require 'cloudenvoy/authenticator'
require 'cloudenvoy/topic'
require 'cloudenvoy/subscription'
require 'cloudenvoy/pub_sub_client'
require 'cloudenvoy/logger_wrapper'
require 'cloudenvoy/publisher_logger'
require 'cloudenvoy/subscriber_logger'
require 'cloudenvoy/message'
require 'cloudenvoy/publisher'
require 'cloudenvoy/subscriber'

# Define and manage Cloud Pub/Sub publishers and subscribers
module Cloudenvoy
  attr_writer :config

  #
  # Cloudenvoy configurator.
  #
  def self.configure
    yield(config)
  end

  #
  # Return the Cloudenvoy configuration.
  #
  # @return [Cloudenvoy::Config] The Cloudenvoy configuration.
  #
  def self.config
    @config ||= Config.new
  end

  #
  # Return the Cloudenvoy logger.
  #
  # @return [Logger] The Cloudenvoy logger.
  #
  def self.logger
    config.logger
  end

  #
  # Publish a message to a topic. Shorthand method to Cloudenvoy::PubSubClient#publish.
  #
  # @param [String] topic The name of the topic
  # @param [Hash, String] payload The message content.
  # @param [Hash] attrs The message attributes.
  #
  # @return [Cloudenvoy::Message] The created message.
  #
  def self.publish(topic, payload, attrs = {})
    PubSubClient.publish(topic, payload, attrs)
  end

  #
  # Publish multiple messages to a topic. Shorthand method to Cloudenvoy::PubSubClient#publish_all.
  #
  # @param [String] topic The name of the topic
  # @param [Array<Array<[Hash, String]>>] msg_args A list of message [payload, metadata].
  #
  # @return [Array<Cloudenvoy::Message>] The published messages.
  #
  def self.publish_all(topic, msg_args)
    PubSubClient.publish_all(topic, msg_args)
  end

  #
  # Return the list of registered publishers.
  #
  # @return [Set<Cloudenvoy::Subscriber>] The list of registered publishers.
  #
  def self.publishers
    @publishers ||= Set.new
  end

  #
  # Return the list of registered subscribers.
  #
  # @return [Set<Cloudenvoy::Subscriber>] The list of registered subscribers.
  #
  def self.subscribers
    @subscribers ||= Set.new
  end

  #
  # Create/update subscriptions for all registered subscribers.
  #
  # @return [Array<Cloudenvoy::Subscription>] The upserted subscriptions.
  #
  def self.setup_subscribers
    subscribers.flat_map(&:setup)
  end

  #
  # Create/update default topics for all registered publishers.
  #
  # @return [Array<Cloudenvoy::Subscription>] The upserted topics.
  #
  def self.setup_publishers
    publishers.flat_map(&:setup)
  end
end

require 'cloudenvoy/engine' if defined?(Rails::Engine)
