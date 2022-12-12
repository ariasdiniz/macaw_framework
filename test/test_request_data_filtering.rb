# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/request_data_filtering"
class TestRequestDataFiltering < Minitest::Test
  def test_extract_client_info
    expected_path = "GET /test_parameters "
    expected_method_name = "get_test_parameters"
    expected_headers = {
      "Content-Type" => "application/json",
      "Accept" => "*/*",
      "Host" => "localhost",
      "Content-Length" => "29"
    }
    expected_body = "{\n    \"testBody\": \"testing\"\n}"
    expected_parameters = {
      "param1" => "11111",
      "param2" => "22222"
    }

    filter = RequestDataFiltering
    client_data = File.open("./test/client_data.txt")
    path, method_name, headers, body, parameters = filter.extract_client_info(client_data)

    assert path == expected_path
    assert body == expected_body
    assert parameters == expected_parameters
    assert headers == expected_headers
    assert method_name == expected_method_name
  end
end
