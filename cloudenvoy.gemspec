# frozen_string_literal: true

require_relative 'lib/cloudenvoy/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloudenvoy'
  spec.version       = Cloudenvoy::VERSION
  spec.authors       = ['Arnaud Lachaume']
  spec.email         = ['arnaud.lachaume@keypup.io']

  spec.summary       = 'Cross-application messaging using GCP Pub/Sub (alpha)'
  spec.description   = 'Cross-application messaging using GCP Pub/Sub (alpha)'
  spec.homepage      = 'https://github.com/keypup-io/cloudenvoy'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/keypup-io/cloudenvoy'
  spec.metadata['changelog_uri'] = 'https://github.com/keypup-io/cloudenvoy/master/tree/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'google-cloud-pubsub', '~> 2.0'
  spec.add_dependency 'jwt'
  spec.add_dependency 'retriable'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.76.0'
  spec.add_development_dependency 'rubocop-rspec', '1.37.0'
  spec.add_development_dependency 'semantic_logger'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'webmock'
end
