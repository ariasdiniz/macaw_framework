# frozen_string_literal: true

require "prometheus/client"
require "prometheus/client/formats/text"

##
# Middleware responsible to configure prometheus
# defining metrics and an endpoint to access them.
class PrometheusMiddleware
  attr_accessor :request_duration_milliseconds, :request_count, :response_count

  def configure_prometheus(prometheus_registry, configurations, macaw)
    return nil unless prometheus_registry

    @request_duration_milliseconds = Prometheus::Client::Histogram.new(
      :request_duration_milliseconds,
      docstring: "The duration of each request in milliseconds",
      labels: [:endpoint],
      buckets: (100..1000).step(100).to_a + (2000..10_000).step(1000).to_a
    )

    @request_count = Prometheus::Client::Counter.new(
      :request_count,
      docstring: "The total number of requests received",
      labels: [:endpoint]
    )

    @response_count = Prometheus::Client::Counter.new(
      :response_count,
      docstring: "The total number of responses sent",
      labels: %i[endpoint status]
    )

    prometheus_registry.register(@request_duration_milliseconds)
    prometheus_registry.register(@request_count)
    prometheus_registry.register(@response_count)
    prometheus_endpoint(prometheus_registry, configurations, macaw)
  end

  private

  def prometheus_endpoint(prometheus_registry, configurations, macaw)
    endpoint = configurations["macaw"]["prometheus"]["endpoint"] || "/metrics"
    macaw.get(endpoint) do |_context|
      [Prometheus::Client::Formats::Text.marshal(prometheus_registry), 200]
    end
  end
end
