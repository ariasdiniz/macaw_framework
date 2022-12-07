# frozen_string_literal: true

require_relative "macaw_framework/endpoint_not_mapped_error"
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
    def initialize
      begin
        config = JSON.parse(File.read("application.json"))
        @port = config["macaw"]["port"]
      rescue StandardError
        @port ||= 8080
      end
      @port ||= 8080
    end

    ##
    # Creates a GET endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {Integer, String}
    def get(path, &block)
      path_clean = path[0] == "/" ? path[1..].gsub("/", "_") : path.gsub("/", "_")
      define_singleton_method("get_#{path_clean}", block)
    end

    ##
    # Creates a POST endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def post(path, &block)
      path_clean = path[0] == "/" ? path[1..].gsub("/", "_") : path.gsub("/", "_")
      define_singleton_method("post_#{path_clean}", block)
    end

    ##
    # Creates a PUT endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def put(path, &block)
      path_clean = path[0] == "/" ? path[1..].gsub("/", "_") : path.gsub("/", "_")
      define_singleton_method("put_#{path_clean}", block)
    end

    ##
    # Creates a PATCH endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def patch(path, &block)
      path_clean = path[0] == "/" ? path[1..].gsub("/", "_") : path.gsub("/", "_")
      define_singleton_method("patch_#{path_clean}", block)
    end

    ##
    # Creates a DELETE endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def delete(path, &block)
      path_clean = path[0] == "/" ? path[1..].gsub("/", "_") : path.gsub("/", "_")
      define_singleton_method("delete_#{path_clean}", block)
    end

    ##
    # Starts the web server
    def start!
      server = TCPServer.open(@port)
      puts "Starting server at port #{@port}"
      loop do
        Thread.start(server.accept) do |client|
          client.select
          method_name, headers, body = extract_client_info(client)
          raise EndpointNotMappedError unless respond_to?(method_name)

          message, status = send(method_name, headers, body)
          status ||= 200
          message ||= "Ok"
          client.puts "HTTP/1.1 #{status} #{HTTP_STATUS_CODE_MAP[status]} \r\n\r\n#{message}"
          client.close
        rescue EndpointNotMappedError
          client.print "HTTP/1.1 404 Not Found\r\n\r\n"
          client.close
        rescue StandardError
          client.print "HTTP/1.1 500 Internal Server Error\r\n\r\n"
          client.close
        end
      end
    rescue Interrupt
      puts "Macaw stop flying for some seeds..."
    end

    private

    ##
    # Method responsible for extracting information
    # provided by the client like Headers and Body
    def extract_client_info(client)
      method_name = client.gets.gsub("HTTP/1.1", "").gsub("/", "_").strip!.downcase
      method_name.gsub!(" ", "")
      body_first_line, headers = extract_headers(client)
      body = extract_body(client, body_first_line, headers["Content-Length"].to_i)
      [method_name, headers, body]
    end

    ##
    # Extract application headers
    def extract_headers(client)
      header = client.gets.delete("\n").delete("\r")
      headers = {}
      while header.match(%r{[a-zA-Z0-9\-/*]*: [a-zA-Z0-9\-/*]})
        split_header = header.split(":")
        headers[split_header[0]] = split_header[1][1..]
        header = client.gets.delete("\n").delete("\r")
      end
      [header, headers]
    end

    def extract_body(client, body_first_line, content_length)
      body = client.read(content_length)
      body_first_line << body.to_s
    end
  end
end
