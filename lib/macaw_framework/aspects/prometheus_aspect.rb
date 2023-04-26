# frozen_string_literal: true

##
# Aspect that provides application metrics using prometheus.
module PrometheusAspect
  def call_endpoint(prometheus_middleware, *args)
    return super(*args) if prometheus_middleware.nil?

    start_time = Time.now

    begin
      response = super(*args)
    ensure
      duration = (Time.now - start_time) * 1_000

      endpoint_name = args[2].split(".").join("/")

      prometheus_middleware.request_duration_milliseconds.with_labels(endpoint: endpoint_name).observe(duration)
      prometheus_middleware.request_count.with_labels(endpoint: endpoint_name).increment
      if response
        prometheus_middleware.response_count.with_labels(endpoint: endpoint_name,
                                                         status: response[1]).increment
      end
    end

    response
  end
end
