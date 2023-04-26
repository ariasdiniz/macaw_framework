# frozen_string_literal: true

##
# Aspect that provide cache for the endpoints.
module CacheAspect
  def call_endpoint(cache, *args)
    return super(*args) unless !cache[:cache].nil? && cache[:endpoints_to_cache].include?(args[0])
    return cache[:cache].cache[args[1..].to_s.to_sym][0] unless cache[:cache].cache[args[1..].to_s.to_sym].nil?

    response = super(*args)
    cache[:cache].cache[args[1..].to_s.to_sym] = [response, Time.now]
    response
  end
end
