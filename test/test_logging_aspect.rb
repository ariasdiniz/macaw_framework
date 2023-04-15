# frozen_string_literal: true

require "logger"
require_relative "test_helper"
require_relative "../lib/macaw_framework/middlewares/server"
require_relative "../lib/macaw_framework/aspects/logging_aspect"

class LoggingAspectTest < Minitest::Test
  include LoggingAspect

  def setup
    @logger = Logger.new(STDOUT)
  end

  def test_logs_input_and_output
    args = ["arg1", "arg2"]
    @logger.stub(:info, nil) do |msg|
      if msg.is_a?(String) && msg.start_with?("Input of my_endpoint:")
        assert_match /#{args}/, msg
      elsif msg.is_a?(String) && msg.start_with?("Output of my_endpoint:")
        assert_equal "Output of my_endpoint: some response", msg
      end
    end

    result = call_endpoint(@logger, :my_endpoint, *args)
    assert_equal "some response", result
  end

  def call_endpoint(logger, *args)
    "some response"
  end
end
