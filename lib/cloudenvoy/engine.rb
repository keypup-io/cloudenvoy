# frozen_string_literal: true

module Cloudenvoy
  # CLoudenvoy Rails engine
  class Engine < ::Rails::Engine
    isolate_namespace Cloudenvoy

    initializer 'cloudenvoy', before: :load_config_initializers do
      Rails.application.routes.append do
        mount Cloudenvoy::Engine, at: '/cloudenvoy'
      end
    end

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.assets false
      g.helper false
    end
  end
end
