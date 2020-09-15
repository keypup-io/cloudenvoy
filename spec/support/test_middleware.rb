# frozen_string_literal: true

class TestMiddleware
  attr_accessor :arg, :called

  def initialize(arg = nil)
    @arg = arg
  end

  def call(processor, **kwargs)
    @called = true
    processor.middleware_called = true if processor.respond_to?(:middleware_called)
    processor.middleware_opts = kwargs if processor.respond_to?(:middleware_opts)
    yield
  end
end
