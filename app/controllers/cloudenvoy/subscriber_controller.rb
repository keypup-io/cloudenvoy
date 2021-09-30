# frozen_string_literal: true

module Cloudenvoy
  # Handle execution of Cloudenvoy subscribers
  class SubscriberController < ActionController::Base
    # No need for CSRF verification on API endpoints
    skip_before_action :verify_authenticity_token

    # Authenticate all requests.
    before_action :authenticate!

    # Return 401 when API Token is invalid
    rescue_from AuthenticationError do
      head :unauthorized
    end

    # POST /cloudenvoy/receive
    #
    # Process a Pub/Sub message using a Cloudenvoy subscriber.
    #
    def receive
      # Process msg_descriptor
      Subscriber.execute_from_descriptor(msg_descriptor)
      head :no_content
    rescue InvalidSubscriberError
      # 404: Message delivery will be retried
      head :not_found
    rescue StandardError
      # 422: Message delivery will be retried
      head :unprocessable_entity
    end

    private

    #
    # Parse the request body and return the actual message
    # descriptor.
    #
    # @return [Hash] The descriptor payload
    #
    def msg_descriptor
      @msg_descriptor ||= begin
        # Get raw body
        content = request.body.read

        # Return content parsed as JSON
        JSON.parse(content).except('token')
      end
    end

    #
    # Authenticate incoming requests via a token parameter
    #
    # See Cloudenvoy::Authenticator#verification_token
    #
    def authenticate!
      Authenticator.verify!(params['token'])
    end
  end
end
