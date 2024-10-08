# frozen_string_literal: true

RSpec.describe Cloudenvoy::Config do
  let(:secret) { 'some-secret' }
  let(:gcp_project_id) { 'some-project-id' }
  let(:gcp_sub_prefix) { 'some-queue' }
  let(:processor_host) { 'http://localhost' }
  let(:processor_path) { nil }
  let(:logger) { Logger.new(nil) }
  let(:mode) { :production }

  let(:rails_hosts) { [] }
  let(:rails_secret) { 'rails_secret' }
  let(:rails_credentials) { { secret_key_base: rails_secret } }
  let(:rails_config) do
    if defined?(Rails) && Rails.application.config.respond_to?(:hosts)
      instance_double(Rails::Application::Configuration, hosts: rails_hosts)
    else
      instance_double(Rails::Application::Configuration)
    end
  end
  let(:rails_app) { instance_double(Dummy::Application, credentials: rails_credentials, config: rails_config) }
  let(:rails_logger) { instance_double(ActiveSupport::Logger) }
  let(:rails_klass) { class_double(Rails, application: rails_app, logger: rails_logger) }

  let(:config) do
    Cloudenvoy.configure do |c|
      c.mode = mode
      c.logger = logger
      c.secret = secret
      c.gcp_project_id = gcp_project_id
      c.gcp_sub_prefix = gcp_sub_prefix
      c.processor_host = processor_host
      c.processor_path = processor_path
    end

    Cloudenvoy.config
  end

  describe '#mode' do
    subject { config.mode }

    context 'with mode specified' do
      it { is_expected.to eq(mode) }
    end

    context 'with no mode and development environment' do
      let(:mode) { nil }

      before { allow(config).to receive(:environment).and_return('development') }
      it { is_expected.to eq(:development) }
    end

    context 'with no mode and other environment' do
      let(:mode) { nil }

      before { allow(config).to receive(:environment).and_return('production') }
      it { is_expected.to eq(:production) }
    end
  end

  describe '#environment' do
    subject { config.environment }

    before { allow(ENV).to receive(:[]).with('CLOUDENVOY_ENV').and_return(nil) }
    before { allow(ENV).to receive(:[]).with('RAILS_ENV').and_return(nil) }
    before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return(nil) }

    context 'with no env-related vars' do
      it { is_expected.to eq('development') }
    end

    context 'with CLOUDENVOY_ENV' do
      before { allow(ENV).to receive(:[]).with('CLOUDENVOY_ENV').and_return('production') }
      it { is_expected.to eq('production') }
    end

    context 'with RACK_ENV' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('production') }
      it { is_expected.to eq('production') }
    end

    context 'with RAILS_ENV' do
      before { allow(ENV).to receive(:[]).with('RAILS_ENV').and_return('production') }
      it { is_expected.to eq('production') }
    end
  end

  describe '#logger' do
    subject { config.logger }

    context 'with logger provided' do
      it { is_expected.to eq(logger) }
    end

    if defined?(Rails)
      context 'with no logger provided and Rails' do
        let(:logger) { nil }

        before { stub_const('Rails', rails_klass) }
        it { is_expected.to eq(rails_logger) }
      end
    else
      context 'with no logger provided and no-Rails' do
        let(:logger) { nil }

        it { is_expected.to be_a(Logger) }
      end
    end
  end

  describe '#secret' do
    subject(:method) { config.secret }

    context 'with value specified via config' do
      it { is_expected.to eq(secret) }
    end

    if defined?(Rails)
      context 'with Rails secret available' do
        let(:secret) { nil }

        before { stub_const('Rails', rails_klass) }
        it { is_expected.to eq(rails_secret) }
      end
    end

    context 'with no value' do
      let(:secret) { nil }

      it { expect { method }.to raise_error(StandardError, described_class::SECRET_MISSING_ERROR) }
    end
  end

  describe '#gcp_project_id' do
    subject(:method) { config.gcp_project_id }

    context 'with value specified via config' do
      it { is_expected.to eq(gcp_project_id) }
    end

    context 'with no value' do
      let(:gcp_project_id) { nil }

      it { expect { method }.to raise_error(StandardError, described_class::PROJECT_ID_MISSING_ERROR) }
    end
  end

  describe '#gcp_sub_prefix' do
    subject(:method) { config.gcp_sub_prefix }

    context 'with value specified via config' do
      it { is_expected.to eq(gcp_sub_prefix) }
    end

    context 'with no value' do
      let(:gcp_sub_prefix) { nil }

      it { expect { method }.to raise_error(StandardError, described_class::SUB_PREFIX_MISSING_ERROR) }
    end
  end

  describe '#processor_host' do
    subject(:method) { config.processor_host }

    if defined?(Rails) && Rails.application.config.respond_to?(:hosts)
      context 'with rails hosts' do
        subject { rails_klass.application.config.hosts }

        let(:rails_hosts) { ['.local'] }
        let(:expected_host) { 'localhost' }

        before { stub_const('Rails', rails_klass) }
        before { config }
        it { is_expected.to include(expected_host) }
      end

      context 'with empty rails hosts' do
        subject { rails_klass.application.config.hosts }

        let(:expected_host) { 'localhost' }

        before { stub_const('Rails', rails_klass) }
        before { config }
        it { is_expected.to be_empty }
      end
    end

    context 'with value specified via config' do
      it { is_expected.to eq(processor_host) }
    end

    context 'with no value' do
      let(:processor_host) { nil }

      it { expect { method }.to raise_error(StandardError, described_class::PROCESSOR_HOST_MISSING) }
    end
  end

  describe '#processor_path' do
    subject { config.processor_path }

    context 'with value specified via config' do
      let(:processor_path) { '/foo' }

      it { is_expected.to eq(processor_path) }
    end

    context 'with no value' do
      let(:processor_path) { nil }

      it { is_expected.to eq(described_class::DEFAULT_PROCESSOR_PATH) }
    end
  end

  describe '#processor_url' do
    subject { config.processor_url }

    it { is_expected.to eq("#{config.processor_host}#{config.processor_path}") }
  end

  describe '#publisher_middleware' do
    subject(:middlewares) { config.publisher_middleware }

    before do
      config.publisher_middleware do |chain|
        chain.add(TestMiddleware)
      end
    end

    it { is_expected.to be_a(Cloudenvoy::Middleware::Chain) }
    it { expect(middlewares).to exist(TestMiddleware) }
  end

  describe '#subscriber_middleware' do
    subject(:middlewares) { config.subscriber_middleware }

    before do
      config.subscriber_middleware do |chain|
        chain.add(TestMiddleware)
      end
    end

    it { is_expected.to be_a(Cloudenvoy::Middleware::Chain) }
    it { expect(middlewares).to exist(TestMiddleware) }
  end
end
