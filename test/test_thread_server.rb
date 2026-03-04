# frozen_string_literal: true

require 'logger'
require 'socket'
require 'net/http'
require 'openssl'
require_relative 'test_helper'
require_relative '../lib/macaw_framework/aspects/logging_aspect'
require_relative '../lib/macaw_framework/utils/http_status_code'
require_relative '../lib/macaw_framework/data_filters/request_data_filtering'
require_relative '../lib/macaw_framework/errors/endpoint_not_mapped_error'

class TestEndpoint
  attr_reader :routes, :port, :bind, :threads, :macaw_log, :cached_methods,
              :keep_alive_timeout
  attr_accessor :config

  def initialize
    @routes = %w[get.hello get.ok get.ise]
    @port = 9292
    @bind = 'localhost'
    @threads = 1
    @macaw_log = nil
    @config = nil
    @cached_methods = []
    @keep_alive_timeout = 30
    define_singleton_method('get.hello', ->(_context) { 'Hello, World!' })
    define_singleton_method('get.ok', ->(_context) { ['Ok', 200] })
    define_singleton_method('get.ise', ->(_context) { raise StandardError, 'Internal server error' })
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
    @bind = 'localhost'
    @num_threads = 4
    @server = ThreadServer.new(@macaw)
  end

  def teardown
    @server&.shutdown
  end

  def test_run_and_close
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    # Send a request to the server
    client = TCPSocket.new(@bind, @port)
    client.puts "GET /hello HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    response = client.read
    client.close

    assert_match(/Hello, World!/, response)

    @server.shutdown
    server_thread.join
  end

  def test_non_existent_endpoint
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "GET /nonexistent HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    response = client.read
    client.close

    assert_match %r{HTTP/1.1 404 Not Found}, response

    @server.shutdown
    server_thread.join
  end

  def test_status_ok
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "GET /ok HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    response = client.read
    client.close

    assert_match %r{HTTP/1.1 200 OK}, response

    @server.shutdown
    server_thread.join
  end

  def test_internal_server_error
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "GET /ise HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    response = client.read
    client.close

    assert_match %r{HTTP/1.1 500 Internal Server Error}, response

    @server.shutdown
    server_thread.join
  end

  def test_post_request
    @macaw.routes << 'post.hello'
    @macaw.define_singleton_method('post.hello', ->(_context) { 'Hello, POST!' })

    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "POST /hello HTTP/1.1\r\nHost: example.com\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
    response = client.read
    client.close

    assert_match(/Hello, POST!/, response)

    @server.shutdown
    server_thread.join
  end

  def test_ssl_feature
    @macaw.config = {
      'macaw' => {
        'ssl' => {
          'cert_file_name' => './test/data/test_cert.pem',
          'key_file_name' => './test/data/test_key.pem'
        }
      }
    }
    @server = ThreadServer.new(@macaw)

    server_thread = Thread.new { @server.run }
    sleep(0.1)

    http = Net::HTTP.new(@bind, @port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new('/hello')
    response = http.request(request)

    assert_equal '200', response.code
    assert_match(/Hello, World!/, response.body)

    @server.shutdown
    server_thread.join
  end

  def test_ssl_config_no_ssl
    @macaw.config = nil
    @server = ThreadServer.new(@macaw)
    assert_nil @server.context
    @server = nil
  end

  def test_ssl_config_with_ssl_no_min_max
    @macaw.config = {
      'macaw' => {
        'ssl' => {
          'cert_file_name' => './test/data/test_cert.pem',
          'key_file_name' => './test/data/test_key.pem'
        }
      }
    }
    @server = ThreadServer.new(@macaw)
    assert_kind_of OpenSSL::SSL::SSLContext, @server.context
    @server = nil
  end

  def test_ssl_config_with_ssl_values
    @macaw.config = {
      'macaw' => {
        'ssl' => {
          'min' => 'TLS1.2',
          'max' => 'TLS1.3',
          'cert_file_name' => './test/data/test_cert.pem',
          'key_file_name' => './test/data/test_key.pem'
        }
      }
    }

    context_mock = Minitest::Mock.new
    context_mock.expect(:min_version=, nil, [OpenSSL::SSL::TLS1_2_VERSION])
    context_mock.expect(:max_version=, nil, [OpenSSL::SSL::TLS1_3_VERSION])
    context_mock.expect(:cert=, nil, [Object])
    context_mock.expect(:key=, nil, [Object])

    OpenSSL::SSL::SSLContext.stub :new, context_mock do
      @server = ThreadServer.new(@macaw)
    end

    assert_mock context_mock
    @server = nil
  end

  def test_ssl_config_with_missing_files
    @macaw.config = {
      'macaw' => {
        'ssl' => {
          'cert_file_name' => './test/data/non_existent_cert.pem',
          'key_file_name' => './test/data/non_existent_key.pem'
        }
      }
    }
    assert_raises Errno::ENOENT do
      ThreadServer.new(@macaw)
    end
    @server = nil
  end

  def test_data_filtering
    @macaw.routes << 'post.test_filter'
    @macaw.define_singleton_method('post.test_filter', ->(context) { context[:body] })

    server_thread = Thread.new { @server.run }
    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "POST /test_filter HTTP/1.1\r\nHost: example.com\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello"
    response = client.read
    client.close

    assert_match(/hello/, response)

    @server.shutdown
    server_thread.join
  end

  def test_ssl_config_with_ecdsa_key
    @macaw.config = {
      'macaw' => {
        'ssl' => {
          'key_type' => 'EC',
          'cert_file_name' => './test/data/ec_cert.crt',
          'key_file_name' => './test/data/ec_key.key'
        }
      }
    }
    @server = ThreadServer.new(@macaw)

    server_thread = Thread.new { @server.run }
    sleep(0.1)

    http = Net::HTTP.new(@bind, @port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new('/hello')
    response = http.request(request)

    assert_equal '200', response.code
    assert_match(/Hello, World!/, response.body)

    @server.shutdown
    server_thread.join
  end

  def test_invalid_ssl_key_type
    @macaw.config = {
      'macaw' => {
        'ssl' => {
          'key_type' => 'INVALID',
          'cert_file_name' => './test/data/test_cert.pem',
          'key_file_name' => './test/data/test_key.pem'
        }
      }
    }

    Thread.new { @server.run }
    sleep(0.1)

    assert_raises ArgumentError do
      ThreadServer.new(@macaw)
    end
  end

  def test_multiple_requests
    server_thread = Thread.new { @server.run }

    sleep(0.1)

    threads = []
    10.times do
      threads << Thread.new do
        client = TCPSocket.new(@bind, @port)
        client.puts "GET /hello HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
        response = client.read
        client.close
        assert_match(/Hello, World!/, response)
      end
    end

    threads.each(&:join)

    @server.shutdown
    server_thread.join
  end

  def test_special_character_request_path
    @macaw.routes << 'get.hello%24world'
    @macaw.define_singleton_method('get.hello%24world', ->(_context) { 'Hello, World!' })

    server_thread = Thread.new { @server.run }

    sleep(0.1)

    client = TCPSocket.new(@bind, @port)
    client.puts "GET /hello%24world HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    response = client.read
    client.close

    assert_match(/Hello, World!/, response)

    @server.shutdown
    server_thread.join
  end

  def test_keep_alive_reuses_connection
    server_thread = Thread.new { @server.run }
    sleep(0.1)

    client = TCPSocket.new(@bind, @port)

    # First request — no Connection: close, server should keep socket open
    request = "GET /ok HTTP/1.1\r\nHost: example.com\r\n\r\n"
    client.write request
    first_response = +''
    first_response << client.readpartial(4096) until first_response.include?("\r\n\r\n")

    assert_match(%r{HTTP/1.1 200 OK}, first_response)
    assert_match(/Connection: keep-alive/, first_response)

    # Second request on the same connection — now close
    client.write "GET /hello HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    second_response = client.read
    client.close

    assert_match(/Hello, World!/, second_response)
    assert_match(/Connection: close/, second_response)

    @server.shutdown
    server_thread.join
  end
end
