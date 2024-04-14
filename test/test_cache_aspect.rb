# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/aspects/cache_aspect"

class TestClass
  prepend CacheAspect

  def call_endpoint(*_args, options)
    status = options[:status] || 200
    ["Original method response", status, { "a" => "b" }]
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

    assert_equal ["Original method response", 200, { "a" => "b" }], response
  end

  def test_cache_not_included
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method2"]
    response = test_class.call_endpoint({ cache: cache, endpoints_to_cache: endpoints_to_cache }, endpoints_to_cache,
                                        "a", { body: "a", headers: "a" })

    assert_equal ["Original method response", 200, { "a" => "b" }], response
  end

  def test_cache_hit
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    cache.cache[:"[{:params=>nil, :headers=>{\"a\"=>\"b\"}}]"] = ["Cached response", Time.now]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b" } }
    )

    assert_equal "Cached response", response
  end

  def test_cache_miss
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b" } }
    )

    assert_equal ["Original method response", 200, { "a" => "b" }], response
    assert_equal(
      ["Original method response", 200, { "a" => "b" }],
      cache.cache[:"[{:params=>nil, :headers=>{\"a\"=>\"b\"}}]"][0]
    )
  end

  def test_cache_miss_with_ignored_header
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b", "correlation-id" => "unique-id-1" } }
    )

    assert_equal ["Original method response", 200, { "a" => "b" }], response
    assert_equal(
      ["Original method response", 200, { "a" => "b" }],
      cache.cache[:"[{:params=>nil, :headers=>{\"a\"=>\"b\"}}]"][0]
    )
  end

  def test_cache_hit_with_ignored_header
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    cache.cache[:"[{:params=>nil, :headers=>{\"a\"=>\"b\"}}]"] = ["Cached response", Time.now]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b", "correlation-id" => "unique-id-2" } }
    )

    assert_equal "Cached response", response
  end

  def test_cache_miss_2xx_status
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b" }, status: 200 }
    )

    assert_equal ["Original method response", 200, { "a" => "b" }], response
    assert_equal(
      ["Original method response", 200, { "a" => "b" }],
      cache.cache[:"[{:params=>nil, :headers=>{\"a\"=>\"b\"}}]"][0]
    )
  end

  def test_cache_miss_3xx_status
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b" }, status: 302 }
    )

    assert_equal ["Original method response", 302, { "a" => "b" }], response
    assert_empty cache.cache
  end

  def test_cache_miss_4xx_status
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b" }, status: 404 }
    )

    assert_equal ["Original method response", 404, { "a" => "b" }], response
    assert_empty cache.cache
  end

  def test_cache_miss_5xx_status
    test_class = TestClass.new
    cache = CacheMock.new
    endpoints_to_cache = ["method1"]
    response = test_class.call_endpoint(
      { cache: cache, endpoints_to_cache: endpoints_to_cache, cached_methods: { "method1" => ["a"] } },
      "method1", { body: "a", params: nil, headers: { "a" => "b" }, status: 500 }
    )

    assert_equal ["Original method response", 500, { "a" => "b" }], response
    assert_empty cache.cache
  end
end
