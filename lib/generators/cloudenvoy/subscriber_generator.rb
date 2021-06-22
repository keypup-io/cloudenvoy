# frozen_string_literal: true

require 'rails/generators/named_base'

module Cloudenvoy
  module Generators # :nodoc:
    class SubscriberGenerator < ::Rails::Generators::NamedBase # :nodoc:
      desc 'This generator creates a CloudEnvoy in app/subscribers and a corresponding test'

      check_class_collision suffix: 'Subscriber'

      def self.default_generator_root
        File.dirname(__FILE__)
      end

      def create_subscriber_file
        template 'subscriber.rb.erb', File.join('app/subscribers', class_path, "#{file_name}_subscriber.rb")
      end

      def create_test_file
        return unless test_framework

        create_subscriber_spec if test_framework == :rspec
      end

      private

      def create_subscriber_spec
        template_file = File.join(
          'spec/subscribers',
          class_path,
          "#{file_name}_subscriber_spec.rb"
        )
        template 'subscriber_spec.rb.erb', template_file
      end

      def file_name
        @file_name ||= super.sub(/_?subscriber\z/i, '')
      end

      def test_framework
        ::Rails.application.config.generators.options[:rails][:test_framework]
      end
    end
  end
end
