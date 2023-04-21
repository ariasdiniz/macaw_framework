# frozen_string_literal: true

##
# Aspect that provide cache for the endpoints.
module CacheAspect
  def call_endpoint(cache, endpoints_to_cache, *args)
    return super(*args) unless endpoints_to_cache.include?(args[0]) && !cache.nil?
    return cache.cache[args[2..].to_s.to_sym][0] unless cache.cache[args[2..].to_s.to_sym].nil?

    response = super(*args)
    cache.cache[args[2..].to_s.to_sym] = [response, Time.now]
    response
  end
end
