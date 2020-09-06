# frozen_string_literal: true

module Cloudenvoy
  # Handle execution of Cloudenvoy subscribers
  class SubscriberController < ApplicationController
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
      Subscriber.execute_from_payload(msg_descriptor)
      head :no_content
    rescue InvalidSubscriberError
      # 404: Message delivery will be retried
      head :not_found
    rescue StandardError => e
      puts e
      # 422: Message delivery will be retried
      Cloudenvoy.logger.error(e)
      Cloudenvoy.logger.error(e.backtrace.join("\n"))
      head :unprocessable_entity
    end

    private

    #
    # Parse the request body and return the actual job
    # payload.
    #
    # @return [Hash] The job payload
    #
    def msg_descriptor
      @msg_descriptor ||= begin
        # Get raw body
        content = request.body.read

        # Return content parsed as JSON and add job retries count
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
