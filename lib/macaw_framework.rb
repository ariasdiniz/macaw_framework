# frozen_string_literal: true

require_relative 'macaw_framework/endpoint_not_mapped_error'
require_relative 'macaw_framework/http_status_code'
require_relative 'macaw_framework/version'
require 'socket'
require 'json'

module MacawFramework
  ##
  # Class responsible for creating endpoints and
  # starting the web server.
  class Macaw
    include(HttpStatusCode)
    def initialize
      begin
        config = JSON.parse(File.read('application.json'))
        @port = config['macaw']['port']
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
      path_clean = path[0] == '/' ? path[1..].gsub('/', '_') : path.gsub('/', '_')
      define_singleton_method("get_#{path_clean}", block)
    end

    ##
    # Creates a POST endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def post(path, &block)
      path_clean = path[0] == '/' ? path[1..].gsub('/', '_') : path.gsub('/', '_')
      define_singleton_method("post_#{path_clean}", block)
    end

    ##
    # Creates a PUT endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def put(path, &block)
      path_clean = path[0] == '/' ? path[1..].gsub('/', '_') : path.gsub('/', '_')
      define_singleton_method("put_#{path_clean}", block)
    end

    ##
    # Creates a PATCH endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def patch(path, &block)
      path_clean = path[0] == '/' ? path[1..].gsub('/', '_') : path.gsub('/', '_')
      define_singleton_method("patch_#{path_clean}", block)
    end

    ##
    # Creates a DELETE endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @return {String, Integer}
    def delete(path, &block)
      path_clean = path[0] == '/' ? path[1..].gsub('/', '_') : path.gsub('/', '_')
      define_singleton_method("delete_#{path_clean}", block)
    end

    ##
    # Starts the web server
    def start!
      server = TCPServer.open(@port)
      puts "Starting server at port #{@port}"
      loop do
        Thread.start(server.accept) do |client|
          method_name = extract_client_info(client)
          raise EndpointNotMappedError unless respond_to?(method_name)

          message, status = send(method_name)
          status ||= 200
          message ||= 'Ok'
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
    end

    private

    ##
    # Method for extracting headers and body from client request
    # STILL IN DEVELOPMENT
    # @todo finish implementation
    def extract_client_info(client)
      method_name = client.gets.gsub('HTTP/1.1', '').gsub('/', '_').strip!.downcase
      method_name.gsub!(' ', '')
      method_name
    end
  end
end
