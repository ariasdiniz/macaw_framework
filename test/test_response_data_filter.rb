# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/data_filters/response_data_filter"

class TestResponseDataFilter < Minitest::Test
  def test_mount_response
    status = 200
    headers = { "Content-Type" => "text/html" }
    body = "Hello, World!"

    expected_response = "HTTP/1.1 200 OK \r\nContent-Type: text/html\r\n\r\nHello, World!"
    actual_response = ResponseDataFilter.mount_response(status, headers, body)

    assert_equal expected_response, actual_response
  end

  def test_mount_response_without_headers
    status = 200
    headers = nil
    body = "Hello, World!"

    expected_response = "HTTP/1.1 200 OK \r\n\r\nHello, World!"
    actual_response = ResponseDataFilter.mount_response(status, headers, body)

    assert_equal expected_response, actual_response
  end

  def test_mount_first_response_line_with_headers
    status = 200
    headers = { "Content-Type" => "text/html" }
    expected_status_line = "HTTP/1.1 200 OK \r\n"
    actual_status_line = ResponseDataFilter.mount_first_response_line(status, headers)

    assert_equal expected_status_line, actual_status_line
  end

  def test_mount_first_response_line_without_headers
    status = 200
    headers = nil
    expected_status_line = "HTTP/1.1 200 OK \r\n\r\n"
    actual_status_line = ResponseDataFilter.mount_first_response_line(status, headers)

    assert_equal expected_status_line, actual_status_line
  end

  def test_mount_response_headers_with_headers_present
    headers = { "Content-Type" => "text/html", "Content-Length" => 42 }
    expected_headers = "Content-Type: text/html\r\nContent-Length: 42\r\n\r\n"
    actual_headers = ResponseDataFilter.mount_response_headers(headers)

    assert_equal expected_headers, actual_headers
  end

  def test_mount_response_headers_with_nil_headers
    headers = nil
    actual_headers = ResponseDataFilter.mount_response_headers(headers)

    assert actual_headers == ""
  end
end
