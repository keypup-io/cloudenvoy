# frozen_string_literal: true

require 'cloudenvoy'

ENV['GOOGLE_AUTH_SUPPRESS_CREDENTIALS_WARNINGS'] ||= 'true'

namespace :cloudenvoy do
  desc 'Create required subscriptions for all subcribers.'
  task setup_subscribers: :environment do
    puts Cloudenvoy.setup_subscribers
  end

  desc 'Create required topics for all publishers.'
  task setup_publishers: :environment do
    puts Cloudenvoy.setup_publishers
  end
end
