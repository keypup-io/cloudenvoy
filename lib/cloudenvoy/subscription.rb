# frozen_string_literal: true

module Cloudenvoy
  # A wrapper class for pub/sub subscriptions. Used to wrap
  # responses.
  class Subscription
    attr_accessor :name, :original

    #
    # Constructor
    #
    # @param [Hash] **kwargs Arguments
    #
    def initialize(**kwargs)
      @name = kwargs&.dig(:name)
      @original = kwargs&.dig(:original)
    end
  end
end
