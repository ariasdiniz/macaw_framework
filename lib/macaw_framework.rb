# frozen_string_literal: true

require_relative "macaw_framework/errors/endpoint_not_mapped_error"
require_relative "macaw_framework/middlewares/prometheus_middleware"
require_relative "macaw_framework/middlewares/request_data_filtering"
require_relative "macaw_framework/middlewares/caching_middleware"
require_relative "macaw_framework/core/server"
require_relative "macaw_framework/version"
require "prometheus/client"
require "logger"
require "socket"
require "json"

module MacawFramework
  ##
  # Class responsible for creating endpoints and
  # starting the web server.
  class Macaw
    ##
    # Array containing the routes defined in the application
    attr_reader :routes

    ##
    # @param {Logger} custom_log
    def initialize(custom_log: nil, server: Server)
      begin
        @routes = []
        @macaw_log ||= custom_log.nil? ? Logger.new($stdout) : custom_log
        config = JSON.parse(File.read("application.json"))
        @port = config["macaw"]["port"] || 8080
        @bind = config["macaw"]["bind"] || "localhost"
        @threads = config["macaw"]["threads"].to_i || 5
        unless config["macaw"]["cache"].nil?
          @cache = CachingMiddleware.new(config["macaw"]["cache"]["cache_invalidation"].to_i || 3_600)
        end
        @prometheus = Prometheus::Client::Registry.new if config["macaw"]["prometheus"]
        @prometheus_middleware = PrometheusMiddleware.new if config["macaw"]["prometheus"]
        @prometheus_middleware.configure_prometheus(@prometheus, config, self) if config["macaw"]["prometheus"]
      rescue StandardError => e
        @macaw_log.error(e.message)
      end
      @port ||= 8080
      @bind ||= "localhost"
      @threads ||= 5
      @endpoints_to_cache = []
      @prometheus ||= nil
      @prometheus_middleware ||= nil
      @server = server.new(self, @macaw_log, @port, @bind, @threads, @endpoints_to_cache, @cache, @prometheus,
                           @prometheus_middleware)
    end

    ##
    # Creates a GET endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {Integer, String}
    def get(path, cache: false, &block)
      map_new_endpoint("get", cache, path, &block)
    end

    ##
    # Creates a POST endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Boolean} cache
    # @param {Proc} block
    # @return {String, Integer}
    def post(path, cache: false, &block)
      map_new_endpoint("post", cache, path, &block)
    end

    ##
    # Creates a PUT endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def put(path, cache: false, &block)
      map_new_endpoint("put", cache, path, &block)
    end

    ##
    # Creates a PATCH endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def patch(path, cache: false, &block)
      map_new_endpoint("patch", cache, path, &block)
    end

    ##
    # Creates a DELETE endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def delete(path, cache: false, &block)
      map_new_endpoint("delete", cache, path, &block)
    end

    ##
    # Starts the web server
    def start!
      @macaw_log.info("---------------------------------")
      @macaw_log.info("Starting server at port #{@port}")
      @macaw_log.info("Number of threads: #{@threads}")
      @macaw_log.info("---------------------------------")
      server_loop(@server)
    rescue Interrupt
      @macaw_log.info("Stopping server")
      @server.close
      @macaw_log.info("Macaw stop flying for some seeds...")
    end

    private

    def server_loop(server)
      server.run
    end

    def map_new_endpoint(prefix, cache, path, &block)
      @endpoints_to_cache << "#{prefix}.#{RequestDataFiltering.sanitize_method_name(path)}" if cache
      path_clean = RequestDataFiltering.extract_path(path)
      @macaw_log.info("Defining #{prefix.upcase} endpoint at /#{path}")
      define_singleton_method("#{prefix}.#{path_clean}", block || lambda {
        |context = { headers: {}, body: "", params: {} }|
                                                         })
      @routes << "#{prefix}.#{path_clean}"
    end
  end
end
