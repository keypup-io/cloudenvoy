# frozen_string_literal: true

# Force logging to be realtime
STDOUT.sync = true

# Require project files
require 'sinatra'
Dir.glob('./config/initializers/*.rb').each { |file| require file }
Dir.glob('./app/publishers/*.rb').each { |file| require file }
Dir.glob('./app/subscribers/*.rb').each { |file| require file }

#---------------------------------------------------
# Routes
#---------------------------------------------------

get '/' do
  'Hello!'
end

post '/cloudenvoy/receive' do
  begin
    # Authenticate request
    Cloudenvoy::Authenticator.verify!(params['token'])

    # Parse message descriptor
    content = request.body.read
    msg_descriptor = JSON.parse(content).except('token')

    # Process message descriptor
    Cloudenvoy::Subscriber.execute_from_descriptor(msg_descriptor)
    return 204
  rescue Cloudenvoy::InvalidSubscriberError
    # 404: Message delivery will be retried
    return 404
  rescue StandardError => e
    # 422: Message delivery will be retried
    logger.info([e.message, e.backtrace].flatten.join("\n"))
    return 422
  end
end
