# frozen_string_literal: true

##
# Testing
class CachingMiddleware
  attr_accessor :cache

  def initialize(inv_time_seconds = 3_600)
    @cache = {}
    Thread.new do
      loop do
        sleep(1)
        @cache.each_pair do |key, value|
          @cache.delete(key) if Time.now - value[1] >= inv_time_seconds
        end
      end
    end
    sleep(2)
  end
end
