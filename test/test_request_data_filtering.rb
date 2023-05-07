# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/data_filters/request_data_filtering"
require_relative "../lib/macaw_framework/errors/endpoint_not_mapped_error"
class TestRequestDataFiltering < Minitest::Test
  def test_extract_client_info
    expected_path = "GET /test_parameters "
    expected_method_name = "get.test_parameters"
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
    client_data = File.open("./test/data/client_data.txt")
    path, method_name, headers, body, parameters = filter.parse_request_data(client_data, [expected_method_name])

    assert path == expected_path
    assert body == expected_body
    assert parameters == expected_parameters
    assert headers == expected_headers
    assert method_name == expected_method_name
  end

  def test_path_with_variables
    expected_path = "POST /test/12345/action/123 "
    expected_method_name = "post.test.:var.action.:var2"
    expected_headers = {
      "Content-Type" => "application/json",
      "Accept" => "*/*",
      "Host" => "localhost",
      "Content-Length" => "29"
    }
    expected_body = "{\n    \"testBody\": \"testing\"\n}"
    expected_parameters = {
      "key" => "value",
      var: "12345",
      var2: "123"
    }

    filter = RequestDataFiltering
    client_data = File.open("./test/data/client_data_path_variable.txt")
    path, method_name, headers, body, parameters = filter.parse_request_data(client_data, [expected_method_name])

    assert path == expected_path
    assert body == expected_body
    assert parameters == expected_parameters
    assert headers == expected_headers
    assert method_name == expected_method_name
  end

  def test_path_with_variables_multiple_routes
    expected_path = "POST /test/12345/action/123 "
    expected_method_name = "post.test.:var.action.:var2"
    expected_headers = {
      "Content-Type" => "application/json",
      "Accept" => "*/*",
      "Host" => "localhost",
      "Content-Length" => "29"
    }
    expected_body = "{\n    \"testBody\": \"testing\"\n}"
    expected_parameters = {
      "key" => "value",
      var: "12345",
      var2: "123"
    }
    routes = %w[post.test.:var.actionnn.:var2 post.teste.:var.action.:var2 post.test.:var.action.:var2]

    filter = RequestDataFiltering
    client_data = File.open("./test/data/client_data_path_variable.txt")
    path, method_name, headers, body, parameters = filter.parse_request_data(client_data, routes)

    assert path == expected_path
    assert body == expected_body
    assert parameters == expected_parameters
    assert headers == expected_headers
    assert method_name == expected_method_name
  end

  def test_path_with_variables_that_doesnt_match
    expected_method_name = "post.test.:var.action.:var2.:var3"

    filter = RequestDataFiltering
    client_data = File.open("./test/data/client_data_path_variable.txt")
    assert_raises(EndpointNotMappedError) { filter.parse_request_data(client_data, [expected_method_name]) }
  end
end
