# frozen_string_literal: true

require 'cloudenvoy/backend/memory_pub_sub'

module Cloudenvoy
  # Enable/Disable test mode for Cloudenvoy
  module Testing
    module_function

    #
    # Set the test mode, either permanently or
    # temporarily (via block).
    #
    # @param [Symbol] mode The test mode.
    #
    # @return [Symbol] The test mode.
    #
    def switch_test_mode(mode)
      if block_given?
        current_mode = @test_mode
        begin
          @test_mode = mode
          yield
        ensure
          @test_mode = current_mode
        end
      else
        @test_mode = mode
      end
    end

    #
    # Set cloudenvoy to real mode temporarily
    #
    # @param [Proc] &block The block to run in real mode
    #
    def enable!(&block)
      switch_test_mode(:enabled, &block)
    end

    #
    # Set cloudenvoy to fake mode temporarily
    #
    # @param [Proc] &block The block to run in fake mode
    #
    def fake!(&block)
      switch_test_mode(:fake, &block)
    end

    #
    # Return true if Cloudenvoy is enabled.
    #
    def enabled?
      !@test_mode || @test_mode == :enabled
    end

    #
    # Return true if Cloudenvoy is in fake mode.
    #
    # @return [Boolean] True if messages should be stored in memory.
    #
    def fake?
      @test_mode == :fake
    end

    #
    # Return true if tasks should be managed in memory.
    #
    # @return [Boolean] True if jobs are managed in memory.
    #
    def in_memory?
      !enabled?
    end
  end
end
