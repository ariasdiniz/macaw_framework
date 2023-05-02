# frozen_string_literal: true

##
# Aspect that provide cache for the endpoints.
module CacheAspect
  def call_endpoint(cache, *args)
    return super(*args) unless !cache[:cache].nil? && cache[:endpoints_to_cache]&.include?(args[0])

    cache_filtered_name = cache_name_filter(args[1], cache[:ignored_headers])

    cache[:cache].mutex.synchronize do
      return cache[:cache].cache[cache_filtered_name][0] unless cache[:cache].cache[cache_filtered_name].nil?

      response = super(*args)
      cache[:cache].cache[cache_filtered_name] = [response, Time.now]
      response
    end
  end

  private

  def cache_name_filter(client_data, ignored_headers)
    filtered_headers = client_data[:headers].filter { |key, _value| !ignored_headers&.include?(key) }
    [{ body: client_data[:body], params: client_data[:params], headers: filtered_headers }].to_s.to_sym
  end
end
