# frozen_string_literal: true

require "logger"
require "socket"
require_relative "test_helper"
require_relative "../lib/macaw_framework/aspects/logging_aspect"
require_relative "../lib/macaw_framework/utils/http_status_code"
require_relative "../lib/macaw_framework/middlewares/request_data_filtering"
require_relative "../lib/macaw_framework/errors/endpoint_not_mapped_error"

class TestEndpoint
  def get_hello(_headers, _body, _parameters)
    "Hello, World!"
  end

  def get_ok(_headers, _body, _parameters)
    ["Ok", 200]
  end

  def get_ise(_headers, _body, _parameters)
    raise StandardError, "Internal server error"
  end
end

module IOData
  def readpartial(size, buf = nil)
    buf ||= String.new
    super(size, buf)
  end

  def read_all
    buf = String.new
    buf << readpartial(1024, buf) until buf.end_with?("\r\n\r\n")
    buf
  end
end

class ServerTest < Minitest::Test
  include HttpStatusCode
  include RequestDataFiltering

  def setup
    @logger = Logger.new($stdout)
    @macaw = TestEndpoint.new
    @port = 9292
    @bind = "localhost"
    @num_threads = 4
    @server = Server.new(@macaw, @logger, @port, @bind, @num_threads)
  end

  def teardown
    @server&.close
  end

  def test_run_and_close
    # Start the server in a separate thread
    server_thread = Thread.new { @server.run }

    # Wait for the server to start up
    sleep(0.1)

    # Send a request to the server
    client = TCPSocket.new(@bind, @port)
    client.puts "GET /hello HTTP/1.1\r\nHost: example.com\r\n\r\n"
    response = client.read
    client.close

    # Check that the response is what we expected
    assert_match(/Hello, World!/, response)

    # Stop the server and join the thread
    @server.close
    server_thread.join
  end

  def test_non_existent_endpoint
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "GET /nonexistent HTTP/1.1\r\nHost: example.com\r\n\r\n"
    response = client.read
    client.close

    assert_match %r{HTTP/1.1 404 Not Found}, response

    @server.close
    server_thread.join
  end

  def test_status_ok
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "GET /ok HTTP/1.1\r\nHost: example.com\r\n\r\n"
    response = client.read
    client.close

    assert_match %r{HTTP/1.1 200 OK}, response

    @server.close
    server_thread.join
  end

  def test_internal_server_error
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "GET /ise HTTP/1.1\r\nHost: example.com\r\n\r\n"
    response = client.read
    client.close

    # Check that the response is a 500 Internal Server Error
    assert_match %r{HTTP/1.1 500 Internal Server Error}, response

    # Stop the server and join the thread
    @server.close
    server_thread.join
  end
end