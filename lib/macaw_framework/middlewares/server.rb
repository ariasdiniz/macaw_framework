# frozen_string_literal: true

require_relative "../aspects/logging_aspect"
require_relative "../utils/http_status_code"

##
# Class responsible for providing a default
# webserver.
class Server
  prepend LoggingAspect
  include HttpStatusCode

  ##
  # Create a new instance of Server.
  # @param {Macaw} macaw
  # @param {Logger} logger
  # @param {Integer} port
  # @param {String} bind
  # @return {Server}
  def initialize(macaw, logger, port, bind)
    @port = port
    @bind = bind
    @macaw = macaw
    @macaw_log = logger
  end

  ##
  # Start running the webserver.
  def run
    @server = TCPServer.new(@bind, @port)
    loop do
      Thread.start(@server.accept) do |client|
        path, method_name, headers, body, parameters = RequestDataFiltering.parse_request_data(client)
        raise EndpointNotMappedError unless @macaw.respond_to?(method_name)

        @macaw_log.info("Running #{path.gsub("\n", "").gsub("\r", "")}")
        message, status = call_endpoint(@macaw_log, method_name, headers, body, parameters)
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
  end

  ##
  # Method Responsible for closing the TCP server.
  def close
    @server.close
  end

  private

  def call_endpoint(name, *arg_array)
    @macaw.send(name.to_sym, *arg_array)
  end
end
