# frozen_string_literal: false

require "logger"
require_relative "test_helper"
require_relative "../lib/macaw_framework/aspects/logging_aspect"
require_relative "../lib/macaw_framework/data_filters/log_data_filter"

class LoggingAspectTest < Minitest::Test
  include LoggingAspect

  def setup
    @logger = Logger.new($stdout)
  end

  def test_logs_sanitized_input_and_output
    args = %w[arg1 arg2]
    sensitive_data = "password=my_password"
    input_data = "Input of my_endpoint: #{args} #{sensitive_data}"
    output_data = "Output of my_endpoint: some response"

    sanitized_input_data = LogDataFilter.sanitize_for_logging(input_data)
    sanitized_output_data = LogDataFilter.sanitize_for_logging(output_data)

    @logger.stub(:info, nil) do |msg|
      if msg.is_a?(String) && msg.start_with?("Input of my_endpoint:")
        assert_equal sanitized_input_data, msg
      elsif msg.is_a?(String) && msg.start_with?("Output of my_endpoint:")
        assert_equal sanitized_output_data, msg
      end
    end

    result = call_endpoint(@logger, :my_endpoint, *args)
    assert_equal "some response", result
  end

  def call_endpoint(_logger, *_args)
    "some response"
  end
end
