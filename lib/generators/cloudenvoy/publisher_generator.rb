require "rails/generators/named_base"

module Cloudenvoy
  module Generators # :nodoc:
    class PublisherGenerator < ::Rails::Generators::NamedBase # :nodoc:
      desc "This generator creates a CloudEnvoy in app/publishers and a corresponding test"

      check_class_collision suffix: "Publisher"

      def self.default_generator_root
        File.dirname(__FILE__)
      end

      def create_publisher_file
        template "publisher.rb.erb", File.join("app/publishers", class_path, "#{file_name}_publisher.rb")
      end

      def create_test_file
        return unless test_framework

        if test_framework == :rspec
          create_publisher_spec
        end
      end

      private

      def create_publisher_spec
        template_file = File.join(
          "spec/publishers",
          class_path,
          "#{file_name}_publisher_spec.rb"
        )
        template "publisher_spec.rb.erb", template_file
      end

      def file_name
        @_file_name ||= super.sub(/_?publisher\z/i, "")
      end

      def test_framework
        ::Rails.application.config.generators.options[:rails][:test_framework]
      end
    end
  end
end
