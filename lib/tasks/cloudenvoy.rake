# frozen_string_literal: true

require 'cloudenvoy'

ENV['GOOGLE_AUTH_SUPPRESS_CREDENTIALS_WARNINGS'] ||= 'true'

namespace :cloudenvoy do
  desc 'Setup publishers and subscribers.'
  task setup: :environment do
    Rake::Task['cloudenvoy:setup_publishers'].invoke
    Rake::Task['cloudenvoy:setup_subscribers'].invoke
  end

  desc 'Create required subscriptions for all subcribers.'
  task setup_subscribers: :environment do
    # Force registration of subscribers
    Rails.application.eager_load!

    # Setup subscriptions
    list = Cloudenvoy.setup_subscribers.sort_by(&:name)

    puts "\n"

    # Notify user when no suscribers
    if list.empty?
      puts 'There are no subscribers defined in your application'
      return
    end

    puts 'The following subscribers are configured:'
    list.each do |e|
      puts "- #{e.name}"
    end

    puts "\n"
  end

  desc 'Create required topics for all publishers.'
  task setup_publishers: :environment do
    # Force registration of publishers
    Rails.application.eager_load!

    # Setup topics
    list = Cloudenvoy.setup_publishers.sort_by(&:name)

    puts "\n"

    # Notify user when no topics
    if list.empty?
      puts 'There are no publishers defined in your application'
      return
    end

    puts 'The following topics are configured:'
    list.each do |e|
      puts "- #{e.name}"
    end

    puts "\n"
  end
end
