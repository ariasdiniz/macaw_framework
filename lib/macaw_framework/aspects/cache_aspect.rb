# frozen_string_literal: true

##
# Aspect that provide cache for the endpoints.
module CacheAspect
  def call_endpoint(cache, *args)
    return super(*args) unless !cache[:cache].nil? && cache[:endpoints_to_cache]&.include?(args[0])

    cache_filtered_name = cache_name_filter(args[1], cache[:cached_methods][args[0]])

    cache[:cache].mutex.synchronize do
      return cache[:cache].cache[cache_filtered_name][0] unless cache[:cache].cache[cache_filtered_name].nil?

      response = super(*args)
      cache[:cache].cache[cache_filtered_name] = [response, Time.now] if should_cache_response?(response[1])
      response
    end
  end

  private

  def cache_name_filter(client_data, cached_methods_params)
    filtered_headers = client_data[:headers]&.filter { |key, _value| cached_methods_params&.include?(key) }
    filtered_params = client_data[:params]&.filter { |key, _value| cached_methods_params&.include?(key) }
    [{ params: filtered_params, headers: filtered_headers }].to_s.to_sym
  end

  def should_cache_response?(status)
    (200..299).include?(status.to_i)
  end
end
