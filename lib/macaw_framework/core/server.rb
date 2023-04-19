# frozen_string_literal: true

require_relative "../aspects/logging_aspect"
require_relative "../utils/http_status_code"
require_relative "../aspects/cache_aspect"

##
# Class responsible for providing a default
# webserver.
class Server
  prepend CacheAspect
  prepend LoggingAspect
  include HttpStatusCode

  ##
  # Create a new instance of Server.
  # @param {Macaw} macaw
  # @param {Logger} logger
  # @param {Integer} port
  # @param {String} bind
  # @param {Integer} num_threads
  # @return {Server}
  def initialize(macaw, logger, port, bind, num_threads, endpoints_to_cache = nil, cache = nil)
    @port = port
    @bind = bind
    @macaw = macaw
    @macaw_log = logger
    @num_threads = num_threads
    @work_queue = Queue.new
    @endpoints_to_cache = endpoints_to_cache || []
    @cache = cache
    @workers = []
  end

  ##
  # Start running the webserver.
  def run
    @server = TCPServer.new(@bind, @port)
    @num_threads.times do
      @workers << Thread.new do
        loop do
          client = @work_queue.pop
          break if client == :shutdown

          handle_client(client)
        end
      end
    end

    loop do
      @work_queue << @server.accept
    rescue IOError, Errno::EBADF
      break
    end
  end

  ##
  # Method Responsible for closing the TCP server.
  def close
    @server.close
    @num_threads.times { @work_queue << :shutdown }
    @workers.each(&:join)
  end

  private

  def handle_client(client)
    path, method_name, headers, body, parameters = RequestDataFiltering.parse_request_data(client, @macaw.routes)
    raise EndpointNotMappedError unless @macaw.respond_to?(method_name)

    @macaw_log.info("Running #{path.gsub("\n", "").gsub("\r", "")}")
    message, status = call_endpoint(@macaw_log, @cache, @endpoints_to_cache, method_name, headers, body, parameters)
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

  def call_endpoint(name, headers, body, parameters)
    @macaw.send(name.to_sym, { headers: headers, body: body, params: parameters })
  end
end