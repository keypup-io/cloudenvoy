# frozen_string_literal: true

require 'bundler/setup'
require 'timecop'
require 'webmock/rspec'
require 'semantic_logger'
require 'active_support/logger'

# Configure Rails dummary app if Rails is in context
if Gem.loaded_specs.key?('rails')
  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path('dummy/config/environment.rb', __dir__)
  require 'rspec/rails'
end

# Require main library (after Rails has done so)
require 'cloudenvoy'
require 'cloudenvoy/testing'

# Require supporting files
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
Dir['./spec/shared/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset context before each test
  config.before do
    Cloudenvoy::Testing.clear_all
    Cloudenvoy.config.publisher_middleware.clear
    Cloudenvoy.config.subscriber_middleware.clear
  end
end

# Configure for tests
Cloudenvoy.configure do |config|
  # GCP
  config.gcp_project_id = 'my-project-id'
  config.gcp_sub_prefix = 'my-app'

  # Processor
  config.secret = 'my$s3cr3t'
  config.processor_host = 'http://localhost'
  config.processor_path = '/mynamespace/run'

  # Logger
  config.logger = Logger.new(nil)
end
