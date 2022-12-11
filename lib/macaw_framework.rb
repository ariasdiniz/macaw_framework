# frozen_string_literal: true

require_relative "macaw_framework/endpoint_not_mapped_error"
require_relative "macaw_framework/request_data_filtering"
require_relative "macaw_framework/http_status_code"
require_relative "macaw_framework/version"
require "socket"
require "json"

module MacawFramework
  ##
  # Class responsible for creating endpoints and
  # starting the web server.
  class Macaw
    include(HttpStatusCode)
    ##
    # @param {Logger} custom_log
    def initialize(custom_log = nil)
      begin
        config = JSON.parse(File.read("application.json"))
        @port = config["macaw"]["port"]
      rescue StandardError
        @port ||= 8080
      end
      @port ||= 8080
      @macaw_log ||= custom_log.nil? ? Logger.new($stdout) : custom_log
    end

    ##
    # Creates a GET endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {Integer, String}
    def get(path, &block)
      path_clean = RequestDataFiltering.extract_path(path)
      map_new_endpoint("get", path_clean, &block)
    end

    ##
    # Creates a POST endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def post(path, &block)
      path_clean = RequestDataFiltering.extract_path(path)
      map_new_endpoint("post", path_clean, &block)
    end

    ##
    # Creates a PUT endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def put(path, &block)
      path_clean = RequestDataFiltering.extract_path(path)
      map_new_endpoint("put", path_clean, &block)
    end

    ##
    # Creates a PATCH endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def patch(path, &block)
      path_clean = RequestDataFiltering.extract_path(path)
      map_new_endpoint("patch", path_clean, &block)
    end

    ##
    # Creates a DELETE endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def delete(path, &block)
      path_clean = path[0] == "/" ? path[1..].gsub("/", "_") : path.gsub("/", "_")
      map_new_endpoint("delete", path_clean, &block)
    end

    ##
    # Starts the web server
    def start!
      @macaw_log.info("Starting server at port #{@port}")
      time = Time.now
      server = TCPServer.open(@port)
      @macaw_log.info("Server started in #{Time.now - time} seconds.")
      loop do
        Thread.start(server.accept) do |client|
          path, method_name, headers, body, parameters = RequestDataFiltering.extract_client_info(client)
          raise EndpointNotMappedError unless respond_to?(method_name)

          @macaw_log.info("Running #{path.gsub("\n", "").gsub("\r", "")}")
          message, status = send(method_name, headers, body, parameters)
          status ||= 200
          message ||= "Ok"
          client.puts "HTTP/1.1 #{status} #{HTTP_STATUS_CODE_MAP[status]} \r\n\r\n#{message}"
          client.close
        rescue EndpointNotMappedError
          client.print "HTTP/1.1 404 Not Found\r\n\r\n"
          client.close
        rescue StandardError => e
          client.print "HTTP/1.1 500 Internal Server Error\r\n\r\n"
          @macaw_log.info("Error: #{e}")
          client.close
        end
      end
    rescue Interrupt
      @macaw_log.info("Stopping server")
      server.close
      @macaw_log.info("Macaw stop flying for some seeds...")
    end

    private

    def map_new_endpoint(prefix, path, &block)
      @macaw_log.info("Defining #{prefix.upcase} endpoint at /#{path}")
      define_singleton_method("#{prefix}_#{path}", block)
    end
  end
end
