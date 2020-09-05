# frozen_string_literal: true

Cloudenvoy.configure do |config|
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
