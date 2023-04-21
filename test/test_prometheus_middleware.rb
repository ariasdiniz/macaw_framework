# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/middlewares/prometheus_middleware"

class MockPrometheusRegistry
  def register(metric); end
end

class TestPrometheusMiddleware < Minitest::Test
  def setup
    @prometheus_middleware = PrometheusMiddleware.new
    @prometheus_registry = MockPrometheusRegistry.new
    @macaw = MacawFramework::Macaw.new
  end

  def test_configure_prometheus_with_registry
    @prometheus_middleware.configure_prometheus(@prometheus_registry, test_configurations, @macaw)

    refute_nil @prometheus_middleware.request_duration_milliseconds
    refute_nil @prometheus_middleware.request_count
    refute_nil @prometheus_middleware.response_count
  end

  def test_configure_prometheus_without_registry
    @prometheus_middleware.configure_prometheus(nil, test_configurations, @macaw)

    assert_nil @prometheus_middleware.request_duration_milliseconds
    assert_nil @prometheus_middleware.request_count
    assert_nil @prometheus_middleware.response_count
  end

  private

  def test_configurations
    {
      "macaw" => {
        "prometheus" => {
          "endpoint" => "/test_metrics"
        }
      }
    }
  end
end
