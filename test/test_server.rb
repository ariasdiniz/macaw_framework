# frozen_string_literal: true

require "logger"
require "socket"
require_relative "test_helper"
require_relative "../lib/macaw_framework/aspects/logging_aspect"
require_relative "../lib/macaw_framework/utils/http_status_code"
require_relative "../lib/macaw_framework/data_filters/request_data_filtering"
require_relative "../lib/macaw_framework/errors/endpoint_not_mapped_error"

class TestEndpoint
  attr_reader :routes, :port, :bind, :threads, :macaw_log

  def initialize
    @routes = %w[get.hello get.ok get.ise]
    @port = 9292
    @bind = "localhost"
    @threads = 4
    @macaw_log = Logger.new($stdout)
    define_singleton_method("get.hello", ->(_context) { "Hello, World!" })
    define_singleton_method("get.ok", ->(_context) { ["Ok", 200] })
    define_singleton_method("get.ise", ->(_context) { raise StandardError, "Internal server error" })
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
    @server = Server.new(@macaw)
  end

  def teardown
    @server&.close
  end

  def test_run_and_close
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    # Send a request to the server
    client = TCPSocket.new(@bind, @port)
    client.puts "GET /hello HTTP/1.1\r\nHost: example.com\r\n\r\n"
    response = client.read
    client.close

    assert_match(/Hello, World!/, response)

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

    assert_match %r{HTTP/1.1 500 Internal Server Error}, response

    @server.close
    server_thread.join
  end
end
