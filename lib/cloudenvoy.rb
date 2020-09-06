# frozen_string_literal: true

require 'cloudenvoy/version'
require 'cloudenvoy/config'

require 'cloudenvoy/authentication_error'
require 'cloudenvoy/invalid_subscriber_error'

require 'cloudenvoy/authenticator'
require 'cloudenvoy/pub_sub_client'
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
  # @return [Google::Cloud::PubSub::Message] The created message.
  #
  def self.publish(topic, payload, attrs = {})
    PubSubClient.publish(topic, payload, attrs)
  end
end

require 'cloudenvoy/engine' if defined?(::Rails::Engine)
