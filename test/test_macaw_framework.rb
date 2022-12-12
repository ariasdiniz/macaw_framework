# frozen_string_literal: true

require_relative "test_helper"

class TestMacawFramework < Minitest::Spec
  before do
    @macaw = MacawFramework::Macaw.new
  end
  def test_that_it_has_a_version_number
    refute_nil ::MacawFramework::VERSION
  end

  def test_define_get_endpoint
    assert !@macaw.respond_to?("get_hello_world")
    @macaw.get("/hello_world") {}
    assert @macaw.respond_to?("get_hello_world")
  end

  def test_define_post_endpoint
    assert !@macaw.respond_to?("post_hello_world")
    @macaw.post("/hello_world") {}
    assert @macaw.respond_to?("post_hello_world")
  end

  def test_define_put_endpoint
    assert !@macaw.respond_to?("put_hello_world")
    @macaw.put("/hello_world") {}
    assert @macaw.respond_to?("put_hello_world")
  end

  def test_define_patch_endpoint
    assert !@macaw.respond_to?("patch_hello_world")
    @macaw.patch("/hello_world") {}
    assert @macaw.respond_to?("patch_hello_world")
  end

  def test_define_delete_endpoint
    assert !@macaw.respond_to?("delete_hello_world")
    @macaw.delete("/hello_world") {}
    assert @macaw.respond_to?("delete_hello_world")
  end
end
