# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/aspects/cache_aspect"

class TestClass
  prepend CacheAspect

  def call_endpoint(*_args)
    "Original method response"
  end
end

class CacheMock
  attr_accessor :cache, :mutex

  def initialize
    @cache = {}
    @mutex = Mutex.new
  end
end

class TestCacheAspect < Minitest::Test
  def test_no_cache
    test_class = TestClass.new
    response = test_class.call_endpoint({ cache: nil, endpoints_to_cache: nil }, "method1", { body: "a", headers: "a" })

    assert_equal "Original method response", response
  end

  def test_cache_not_included
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method2"]
    response = test_class.call_endpoint({ cache: cache, endpoints_to_cache: endpoints_to_cache }, endpoints_to_cache,
                                        "a", { body: "a", headers: "a" })

    assert_equal "Original method response", response
  end

  def test_cache_hit
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    cache.cache[:"[{:body=>\"a\", :params=>nil, :headers=>{\"a\"=>\"b\"}}]"] = ["Cached response", Time.now]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, ignored_headers: [] },
      "method1", { body: "a", params: nil, headers: { "a" => "b" } }
    )

    assert_equal "Cached response", response
  end

  def test_cache_miss
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, ignored_headers: [] },
      "method1", { body: "a", params: nil, headers: { "a" => "b" } }
    )

    assert_equal "Original method response", response
    assert_equal(
      "Original method response",
      cache.cache[:"[{:body=>\"a\", :params=>nil, :headers=>{\"a\"=>\"b\"}}]"][0]
    )
  end

  def test_cache_miss_with_ignored_header
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, ignored_headers: ["correlation-id"] },
      "method1", { body: "a", params: nil, headers: { "a" => "b", "correlation-id" => "unique-id-1" } }
    )

    assert_equal "Original method response", response
    assert_equal(
      "Original method response",
      cache.cache[:"[{:body=>\"a\", :params=>nil, :headers=>{\"a\"=>\"b\"}}]"][0]
    )
  end

  def test_cache_hit_with_ignored_header
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    cache.cache[:"[{:body=>\"a\", :params=>nil, :headers=>{\"a\"=>\"b\"}}]"] = ["Cached response", Time.now]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, ignored_headers: ["correlation-id"] },
      "method1", { body: "a", params: nil, headers: { "a" => "b", "correlation-id" => "unique-id-2" } }
    )

    assert_equal "Cached response", response
  end
end
