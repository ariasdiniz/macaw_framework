# frozen_string_literal: true

##
# Middleware responsible for implementing
# rate limiting
class RateLimiterMiddleware
  attr_reader :window_size, :max_requests

  def initialize(window_size, max_requests)
    @window_size = window_size
    @max_requests = max_requests
    @client_timestamps = Hash.new { |key, value| key[value] = [] }
    @mutex = Mutex.new
  end

  def allow?(client_id)
    @mutex.synchronize do
      now = Time.now.to_i
      timestamps = @client_timestamps[client_id]

      timestamps.reject! { |timestamp| timestamp <= now - window_size }

      if timestamps.length < max_requests
        timestamps << now
        true
      else
        false
      end
    end
  end
end
