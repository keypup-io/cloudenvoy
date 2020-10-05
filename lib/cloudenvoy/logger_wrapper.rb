# frozen_string_literal: true

module Cloudenvoy
  # Add contextual information to logs generated
  # by subscribers/publishers.
  #
  # This class is a base class which aims at being inherited by
  # object-specific logger wrappers. See Cloudenvoy::SubscriberLogger
  # and Cloudenvoy::PublisherLogger.
  class LoggerWrapper
    attr_accessor :loggable

    class << self
      attr_accessor :log_context_processor
    end

    #
    # The default context processor. Aims at being overriden by
    # child classes.
    #
    # @return [Proc] The context processor proc.
    #
    def self.default_context_processor
      @default_context_processor ||= ->(_) { {} }
    end

    #
    # Build a new instance of the class.
    #
    # @param [Any] loggable The loggable to wrap for logging.
    #
    def initialize(loggable)
      @loggable = loggable
    end

    #
    # Return the Proc responsible for formatting the log payload.
    #
    # @return [Proc] The context processor.
    #
    def context_processor
      @context_processor ||= loggable.class.cloudenvoy_options_hash[:log_context_processor] ||
                             self.class.log_context_processor ||
                             self.class.default_context_processor
    end

    #
    # The block to pass to log messages.
    #
    # @return [Proc] The log block.
    #
    def log_block
      @log_block ||= proc { context_processor.call(loggable) }
    end

    #
    # Return the Cloudenvoy logger.
    #
    # @return [Logger, any] The cloudenvoy logger.
    #
    def logger
      Cloudenvoy.logger
    end

    #
    # Format main log message.
    #
    # @param [String] msg The message to log.
    #
    # @return [String] The formatted log message
    #
    def formatted_message(msg)
      "[Cloudenvoy][#{loggable.class}] #{msg}"
    end

    #
    # Log an info message.
    #
    # @param [String] msg The message to log.
    # @param [Proc] &block Optional context block.
    #
    def info(msg, &block)
      log_message(:info, msg, &block)
    end

    #
    # Log an error message.
    #
    # @param [String] msg The message to log.
    # @param [Proc] &block Optional context block.
    #
    def error(msg, &block)
      log_message(:error, msg, &block)
    end

    #
    # Log an fatal message.
    #
    # @param [String] msg The message to log.
    # @param [Proc] &block Optional context block.
    #
    def fatal(msg, &block)
      log_message(:fatal, msg, &block)
    end

    #
    # Log an debut message.
    #
    # @param [String] msg The message to log.
    # @param [Proc] &block Optional context block.
    #
    def debug(msg, &block)
      log_message(:debug, msg, &block)
    end

    #
    # Delegate all methods to the underlying logger.
    #
    # @param [String, Symbol] name The method to delegate.
    # @param [Array<any>] *args The list of method arguments.
    # @param [Proc] &block Block passed to the method.
    #
    # @return [Any] The method return value
    #
    def method_missing(name, *args, &block)
      if logger.respond_to?(name)
        logger.send(name, *args, &block)
      else
        super
      end
    end

    #
    # Check if the class respond to a certain method.
    #
    # @param [String, Symbol] name The name of the method.
    # @param [Boolean] include_private Whether to check private methods or not. Default to false.
    #
    # @return [Boolean] Return true if the class respond to this method.
    #
    def respond_to_missing?(name, include_private = false)
      logger.respond_to?(name) || super
    end

    private

    #
    # Log a message for the provided log level.
    #
    # @param [String, Symbol] level The log level
    # @param [String] msg The message to log.
    # @param [Proc] &block Optional context block.
    #
    def log_message(level, msg, &block)
      # Merge log-specific context into object-specific context
      payload_block = ->(*_args) { log_block.call.merge(block&.call || {}) }

      # ActiveSupport::Logger does not support passing a payload through a block on top
      # of a message.
      if defined?(ActiveSupport::Logger) && logger.is_a?(ActiveSupport::Logger)
        logger.send(level) { "#{formatted_message(msg)} -- #{payload_block.call}" }
      else
        logger.send(level, formatted_message(msg), &payload_block)
      end
    end
  end
end
