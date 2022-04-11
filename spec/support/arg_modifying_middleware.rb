# frozen_string_literal: true

# A middleware that stamps all hash arguments
class ArgModifyingMiddleware
  def call(processor, **_kwargs)
    processor.msg_args = processor.msg_args.map { |e| e.merge(_middleware_called: true) }
    yield
  end
end
