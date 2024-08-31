# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/macaw_framework'

class TestCacheClass < Minitest::Test
  def setup
    @cache = MacawFramework::Cache.instance
    @cache.invalidation_frequency = 0.5
  end

  def test_cache_hit
    @cache.write('foo', 'bar')
    assert(@cache.read('foo') == 'bar')
  end

  def test_cache_miss
    @cache.write('foo', 'bar')
    assert(@cache.read('bar').nil?)
  end

  def test_invalidation
    @cache.write('foo', 'bar', expires_in: 1)
    assert(@cache.read('foo') == 'bar')
    sleep(3)
    assert(@cache.read('foo').nil?)
  end

  def test_not_yet_invalid
    @cache.write('foo', 'bar', expires_in: 60)
    assert(@cache.read('foo') == 'bar')
    sleep(3)
    assert(@cache.read('foo') == 'bar')
  end
end
