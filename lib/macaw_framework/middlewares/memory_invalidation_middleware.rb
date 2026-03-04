# frozen_string_literal: true

##
# Middleware responsible for storing and
# invalidating cache.
class MemoryInvalidationMiddleware
  attr_accessor :cache, :mutex

  def initialize(inv_time_seconds = 3_600)
    @cache = {}
    @mutex = Mutex.new
    Thread.new do
      loop do
        sleep(1)
        @mutex.synchronize do
          @cache.each_pair do |key, value|
            @cache.delete(key) if Time.now - value[1] >= inv_time_seconds
          end
        end
      rescue StandardError => e
        # Log and continue so the eviction thread never dies silently
        warn "MemoryInvalidationMiddleware eviction error: #{e.message}"
      end
    end
  end
end
