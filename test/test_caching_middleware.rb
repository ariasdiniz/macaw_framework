# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/middlewares/memory_invalidation_middleware"

class TestCachingMiddleware < Minitest::Test
  def test_initialize
    cache_middleware = MemoryInvalidationMiddleware.new
    assert_instance_of MemoryInvalidationMiddleware, cache_middleware
    assert_equal({}, cache_middleware.cache)
  end

  def test_cache_addition
    cache_middleware = MemoryInvalidationMiddleware.new
    time_now = Time.now
    cache_middleware.cache[:key1] = ["Value1", time_now]
    assert_equal({ key1: ["Value1", time_now] }, cache_middleware.cache)
  end

  def test_cache_expiration
    cache_middleware = MemoryInvalidationMiddleware.new(2)
    cache_middleware.cache[:key1] = ["Value1", Time.now]

    sleep(3)

    assert_empty(cache_middleware.cache)
  end
end
