# frozen_string_literal: true

require_relative "macaw_framework/errors/endpoint_not_mapped_error"
require_relative "macaw_framework/middlewares/request_data_filtering"
require_relative "macaw_framework/middlewares/server"
require_relative "macaw_framework/version"
require "logger"
require "socket"
require "json"

module MacawFramework
  ##
  # Class responsible for creating endpoints and
  # starting the web server.
  class Macaw
    ##
    # @param {Logger} custom_log
    def initialize(custom_log: nil, server: Server)
      begin
        @macaw_log ||= custom_log.nil? ? Logger.new($stdout) : custom_log
        config = JSON.parse(File.read("application.json"))
        @port = config["macaw"]["port"]
        @bind = config["macaw"]["bind"]
        @threads = config["macaw"]["threads"].to_i
      rescue StandardError => e
        @macaw_log.error(e.message)
      end
      @port ||= 8080
      @bind ||= "localhost"
      @threads ||= 5
      @server = server.new(self, @macaw_log, @port, @bind, @threads)
    end

    ##
    # Creates a GET endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {Integer, String}
    def get(path, &block)
      map_new_endpoint("get", path, &block)
    end

    ##
    # Creates a POST endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def post(path, &block)
      map_new_endpoint("post", path, &block)
    end

    ##
    # Creates a PUT endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def put(path, &block)
      map_new_endpoint("put", path, &block)
    end

    ##
    # Creates a PATCH endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def patch(path, &block)
      map_new_endpoint("patch", path, &block)
    end

    ##
    # Creates a DELETE endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def delete(path, &block)
      map_new_endpoint("delete", path, &block)
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

    def map_new_endpoint(prefix, path, &block)
      path_clean = RequestDataFiltering.extract_path(path)
      @macaw_log.info("Defining #{prefix.upcase} endpoint at /#{path}")
      define_singleton_method("#{prefix}_#{path_clean}", block || lambda {
        |context = { headers: {}, body: "", params: {} }|
                                                         })
    end
  end
end
