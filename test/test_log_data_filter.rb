# frozen_string_literal: false

require_relative "test_helper"
require_relative "../lib/macaw_framework/data_filters/log_data_filter"

class TestLogDataFilter < Minitest::Test
  def test_sanitize_for_logging_without_sensitive_fields
    data = "This is a test string without sensitive fields."
    sanitized_data = LogDataFilter.sanitize_for_logging(data)

    assert_equal data, sanitized_data
  end

  def test_sanitize_for_logging_with_sensitive_fields
    data = "This is a test string with sensitive fields: password=my_password api_key=my_api_key"
    sensitive_fields = %w[password api_key]
    sanitized_data = LogDataFilter.sanitize_for_logging(data, sensitive_fields: sensitive_fields)

    refute_equal data, sanitized_data
    refute sanitized_data.include?("my_password")
    refute sanitized_data.include?("my_api_key")
  end

  def test_sanitize_for_logging_truncate_data
    long_data = "A" * 600
    truncated_data = "A" * LogDataFilter.config[:max_length]

    sanitized_data = LogDataFilter.sanitize_for_logging(long_data)
    assert_equal truncated_data, sanitized_data
  end
end
