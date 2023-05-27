# frozen_string_literal: true

require_relative "common/server_base"
require "openssl"

##
# Class responsible for providing a multi threaded
# webserver with Ruby Ractors. This Server is not subject
# to the MRI Global Interpreter Lock, thus it will use
# available physical threads for parallelism.
class RactorServer
  include ServerBase
  # rubocop:disable Metrics/ParameterLists

  attr_reader :context

  ##
  # Create a new instance of ThreadServer.
  # @param {Macaw} macaw
  # @param {Logger} logger
  # @param {Integer} port
  # @param {String} bind
  # @param {Integer} num_threads
  # @param {MemoryInvalidationMiddleware} cache
  # @param {Prometheus::Client:Registry} prometheus
  # @return {ThreadServer}
  def initialize(macaw, endpoints_to_cache = nil, cache = nil, prometheus = nil, prometheus_mw = nil); end

  # rubocop:enable Metrics/ParameterLists

  ##
  # Start running the webserver.
  def run; end

  ##
  # Method Responsible for closing the TCP server.
  def close; end
end
