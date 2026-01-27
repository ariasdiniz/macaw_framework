# frozen_string_literal: true

##
# Main module for all Macaw classes
module MacawFramework; end

##
# This singleton class allows to manually cache
# parameters and other data.
class MacawFramework::Cache
  include Singleton

  attr_accessor :invalidation_frequency

  ##
  # Write a value to Cache memory.
  # Can be called statically or from an instance.
  # @param {String} tag
  # @param {Object} value
  # @param {Integer} expires_in Defaults to 3600.
  # @return nil
  #
  # @example
  #   MacawFramework::Cache.write("name", "Maria", expires_in: 7200)
  def self.write(tag, value, expires_in: 3600)
    MacawFramework::Cache.instance.write(tag, value, expires_in: expires_in)
  end

  ##
  # Write a value to Cache memory.
  # Can be called statically or from an instance.
  # @param {String} tag
  # @param {Object} value
  # @param {Integer} expires_in Defaults to 3600.
  # @return nil
  #
  # @example
  #   MacawFramework::Cache.write("name", "Maria", expires_in: 7200)
  def write(tag, value, expires_in: 3600)
    if read(tag).nil?
      @mutex.synchronize do
        @cache.store(tag, { value: value, expires_in: Time.now + expires_in })
      end
    else
      @cache[tag][:value] = value
      @cache[tag][:expires_in] = Time.now + expires_in
    end
  end

  ##
  # Read the value with the specified tag.
  # Can be called statically or from an instance.
  # @param {String} tag
  # @return {String|nil}
  #
  # @example
  #   MacawFramework::Cache.read("name") # Maria
  def self.read(tag) = MacawFramework::Cache.instance.read(tag)

  ##
  # Read the value with the specified tag.
  # Can be called statically or from an instance.
  # @param {String} tag
  # @return {String|nil}
  #
  # @example
  #   MacawFramework::Cache.read("name") # Maria
  def read(tag) = @cache.dig(tag, :value)

  private

  def initialize
    @cache = {}
    @mutex = Mutex.new
    @invalidation_frequency = 60
    invalidate_cache
  end

  def invalidate_cache
    @invalidator = Thread.new(&method(:invalidation_process))
  end

  def invalidation_process
    loop do
      sleep @invalidation_frequency
      @mutex.synchronize do
        @cache.delete_if { |_, v| v[:expires_in] < Time.now }
      end
    end
  end
end
