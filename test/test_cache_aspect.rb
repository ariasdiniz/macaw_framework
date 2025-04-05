# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/macaw_framework/aspects/cache_aspect'
require 'ostruct'

class DummyBase
  attr_reader :call_count, :last_args, :last_kwargs

  def initialize
    @call_count = 0
  end

  def call_endpoint(*args, **kwargs)
    @call_count += 1
    @last_args = args
    @last_kwargs = kwargs
    @response || ['base_result', 200]
  end

  def define_response(response)
    @response = response
  end
end

class DummyEndpoint < DummyBase
  include CacheAspect
end

class CacheAspectTest < Minitest::Test
  def setup
    @dummy = DummyEndpoint.new
    @cache_obj = {
      cache: OpenStruct.new(mutex: Mutex.new, cache: {}),
      endpoints_to_cache: ['endpoint1'],
      cached_methods: { 'endpoint1' => %i[allowed_header allowed_param] }
    }
    @client_data = {
      headers: { allowed_header: 'value1', not_allowed: 'value2' },
      params: { allowed_param: 'param1', other: 'param2' }
    }
  end

  def test_no_cache_when_cache_nil
    cache = @cache_obj.dup
    cache[:cache] = nil
    @dummy.define_response(['result_no_cache', 200])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    assert_equal ['result_no_cache', 200], result
    assert_equal 1, @dummy.call_count
  end

  def test_no_cache_when_endpoint_not_in_cache_list
    cache = @cache_obj.dup
    cache[:endpoints_to_cache] = ['other_endpoint']
    @dummy.define_response(['result_no_cache', 200])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    assert_equal ['result_no_cache', 200], result
    assert_equal 1, @dummy.call_count
  end

  def test_cache_miss_and_store_successful_response
    cache = @cache_obj.dup
    @dummy.define_response(['fresh_result', 200])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    assert_equal ['fresh_result', 200], result
    assert_equal 1, @dummy.call_count

    filtered = { params: { allowed_param: 'param1' }, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    assert cache[:cache].cache.key?(expected_key)
    cached_value = cache[:cache].cache[expected_key]
    assert_equal ['fresh_result', 200], cached_value[0]
  end

  def test_cache_miss_no_store_on_unsuccessful_response
    cache = @cache_obj.dup
    @dummy.define_response(['error_result', 404])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    assert_equal ['error_result', 404], result
    assert_equal 1, @dummy.call_count

    filtered = { params: { allowed_param: 'param1' }, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    refute cache[:cache].cache.key?(expected_key)
  end

  def test_cache_hit_returns_cached_value_without_calling_super
    cache = @cache_obj.dup
    filtered = { params: { allowed_param: 'param1' }, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    cached_response = ['cached_result', 200]
    cache[:cache].cache[expected_key] = [cached_response, Time.now]
    initial_call_count = @dummy.call_count
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    assert_equal cached_response, result
    assert_equal initial_call_count, @dummy.call_count
  end

  def test_kwargs_are_passed_to_super
    cache = @cache_obj.dup
    @dummy.define_response(['result_kw', 200])
    kwargs = { key: 'value' }
    result = @dummy.call_endpoint(cache, 'not_cached_endpoint', @client_data, **kwargs)
    assert_equal ['result_kw', 200], result
    assert_equal kwargs, @dummy.last_kwargs
  end

  def test_cache_key_with_missing_headers
    cache = @cache_obj.dup
    client_data = { params: { allowed_param: 'param1' } }
    @dummy.define_response(['fresh_result', 200])
    @dummy.call_endpoint(cache, 'endpoint1', client_data)
    filtered = { params: { allowed_param: 'param1' }, headers: nil }
    expected_key = [filtered].to_s.to_sym
    assert cache[:cache].cache.key?(expected_key)
  end

  def test_cache_key_with_missing_params
    cache = @cache_obj.dup
    client_data = { headers: { allowed_header: 'value1' } }
    @dummy.define_response(['fresh_result', 200])
    @dummy.call_endpoint(cache, 'endpoint1', client_data)
    filtered = { params: nil, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    assert cache[:cache].cache.key?(expected_key)
  end

  def test_cache_boundary_status299
    cache = @cache_obj.dup
    @dummy.define_response(['boundary_result', 299])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    filtered = { params: { allowed_param: 'param1' }, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    assert cache[:cache].cache.key?(expected_key)
    assert_equal ['boundary_result', 299], result
  end

  def test_cache_boundary_status300
    cache = @cache_obj.dup
    @dummy.define_response(['non_cache_result', 300])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    filtered = { params: { allowed_param: 'param1' }, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    refute cache[:cache].cache.key?(expected_key)
    assert_equal ['non_cache_result', 300], result
  end

  def test_cache_boundary_status400
    cache = @cache_obj.dup
    @dummy.define_response(['non_cache_result', 400])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    filtered = { params: { allowed_param: 'param1' }, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    refute cache[:cache].cache.key?(expected_key)
    assert_equal ['non_cache_result', 400], result
  end

  def test_cache_boundary_status500
    cache = @cache_obj.dup
    @dummy.define_response(['non_cache_result', 500])
    result = @dummy.call_endpoint(cache, 'endpoint1', @client_data)
    filtered = { params: { allowed_param: 'param1' }, headers: { allowed_header: 'value1' } }
    expected_key = [filtered].to_s.to_sym
    refute cache[:cache].cache.key?(expected_key)
    assert_equal ['non_cache_result', 500], result
  end
end
