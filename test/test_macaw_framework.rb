# frozen_string_literal: true

require_relative "test_helper"
require "net/http"

class TestMacawFramework < Minitest::Spec
  before do
    @macaw = MacawFramework::Macaw.new(custom_log: nil)
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
    macaw = MacawFramework::Macaw.new(custom_log: nil)
    macaw.get("/cache_test", cache: true) {}
    assert_includes macaw.instance_variable_get(:@endpoints_to_cache), "get.cache_test"
  end

  def test_endpoint_without_cache_configuration
    macaw = MacawFramework::Macaw.new(custom_log: nil)
    macaw.get("/no_cache_test") {}
    refute_includes macaw.instance_variable_get(:@endpoints_to_cache), "get.no_cache_test"
  end

  def test_start_without_server
    instance = MacawFramework::Macaw.new(custom_log: nil)

    Thread.new do
      sleep(1)
      Thread.main.raise Interrupt
    end

    assert_output(/Macaw stop flying for some seeds./) do
      instance.start_without_server!
    end
  end

  def test_start
    instance = MacawFramework::Macaw.new(custom_log: nil)

    Thread.new do
      sleep(3)
      Thread.main.raise Interrupt
    end

    assert_output(/Macaw stop flying for some seeds./) do
      instance.start!
    end
  end

  def test_create_endpoints_for_public_files
    instance = MacawFramework::Macaw.new(custom_log: nil, dir: __dir__)

    assert_respond_to instance, "get.public.teste.txt"
    assert_respond_to instance, "get.public.img.img.png"
  end
end
