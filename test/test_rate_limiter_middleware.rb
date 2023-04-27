# frozen_string_literal: true

require "test_helper"
require_relative "../lib/macaw_framework/middlewares/rate_limiter_middleware"

class TestRateLimiterMiddleware < Minitest::Test
  def setup
    @window_size = 10
    @max_requests = 5
    @rate_limiter = RateLimiterMiddleware.new(@window_size, @max_requests)
    @client_id = "127.0.0.1"
  end

  def test_allow_within_limits
    @max_requests.times do
      assert_equal true, @rate_limiter.allow?(@client_id)
    end
  end

  def test_reject_when_exceeding_limits
    @max_requests.times { @rate_limiter.allow?(@client_id) }
    assert_equal false, @rate_limiter.allow?(@client_id)
  end

  def test_allow_after_window_passed
    @max_requests.times { @rate_limiter.allow?(@client_id) }
    sleep(@window_size + 1)
    assert_equal true, @rate_limiter.allow?(@client_id)
  end

  def test_allow_different_clients
    client_id2 = "127.0.0.2"
    @max_requests.times do
      assert_equal true, @rate_limiter.allow?(@client_id)
      assert_equal true, @rate_limiter.allow?(client_id2)
    end
  end
end
