# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/macaw_framework/aspects/prometheus_aspect'

class MockServer
  include PrometheusAspect

  def call_endpoint(_prometheus_middleware, *args)
    endpoint_name = args[3].split('.').join('/')
    puts "Called endpoint: #{endpoint_name}"
    [nil, 200]
  end
end

class MockPrometheusMiddleware
  attr_reader :request_duration_milliseconds, :request_count, :response_count

  def initialize
    @request_duration_milliseconds = MockHistogram.new
    @request_count = MockCounter.new
    @response_count = MockCounter.new
  end

  class MockHistogram
    def with_labels(_labels)
      self
    end

    def observe(value)
      puts "Observed duration: #{value} ms"
    end
  end

  class MockCounter
    def with_labels(_labels)
      self
    end

    def increment
      puts 'Counter incremented'
    end
  end
end

class TestPrometheusAspect < Minitest::Test
  def test_call_endpoint
    server = MockServer.new
    prometheus_middleware = MockPrometheusMiddleware.new

    response = server.call_endpoint(prometheus_middleware, nil, nil, nil, 'get.example')

    assert_equal 200, response[1], 'Expected status 200'
  end
end
