# frozen_string_literal: true

require_relative "test_helper"
require "net/http"

class TestMacawFramework < Minitest::Spec
  before do
    @macaw = MacawFramework::Macaw.new
  end
  def test_that_it_has_a_version_number
    refute_nil ::MacawFramework::VERSION
  end

  def test_define_get_endpoint
    assert !@macaw.respond_to?("get.hello_world")
    @macaw.get("/hello_world") {}
    assert @macaw.respond_to?("get.hello_world")
  end

  def test_define_post_endpoint
    assert !@macaw.respond_to?("post.hello_world")
    @macaw.post("/hello_world") {}
    assert @macaw.respond_to?("post.hello_world")
  end

  def test_define_put_endpoint
    assert !@macaw.respond_to?("put.hello_world")
    @macaw.put("/hello_world") {}
    assert @macaw.respond_to?("put.hello_world")
  end

  def test_define_patch_endpoint
    assert !@macaw.respond_to?("patch.hello_world")
    @macaw.patch("/hello_world") {}
    assert @macaw.respond_to?("patch.hello_world")
  end

  def test_define_delete_endpoint
    assert !@macaw.respond_to?("delete.hello_world")
    @macaw.delete("/hello_world") {}
    assert @macaw.respond_to?("delete.hello_world")
  end

  def test_initialize_with_custom_logger
    custom_logger = Logger.new($stdout)
    macaw = MacawFramework::Macaw.new(custom_log: custom_logger)
    assert_equal custom_logger, macaw.macaw_log
  end

  def test_endpoint_cache_configuration
    macaw = MacawFramework::Macaw.new
    macaw.get("/cache_test", cache: true) {}
    assert_includes macaw.instance_variable_get(:@endpoints_to_cache), "get.cache_test"
  end

  def test_endpoint_without_cache_configuration
    macaw = MacawFramework::Macaw.new
    macaw.get("/no_cache_test") {}
    refute_includes macaw.instance_variable_get(:@endpoints_to_cache), "get.no_cache_test"
  end
end
