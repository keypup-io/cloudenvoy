# frozen_string_literal: true

require 'cloudenvoy/version'
require 'cloudenvoy/config'

require 'cloudenvoy/authentication_error'

require 'cloudenvoy/authenticator'

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
end
