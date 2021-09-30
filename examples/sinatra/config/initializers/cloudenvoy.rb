# frozen_string_literal: true

# Require cloudenvoy and its extensions
require 'cloudenvoy'

Cloudenvoy.configure do |config|
  #
  # Secret used to authenticate job requests
  #
  config.secret = 'some-secret'

  #
  # GCP Configuration
  #
  config.gcp_project_id = 'some-project'
  config.gcp_sub_prefix = 'my-app'

  #
  # Domain
  #
  # config.processor_host = 'https://xxxx.ngrok.io'
  #
  config.processor_host = 'http://localhost:3000'

  #
  # Uncomment to process messages via Pub/Sub.
  # Requires a ngrok tunnel.
  #
  # config.mode = :production
end
