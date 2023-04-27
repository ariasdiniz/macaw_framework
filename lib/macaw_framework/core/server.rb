# frozen_string_literal: true

require_relative "../middlewares/rate_limiter_middleware"
require_relative "../data_filters/response_data_filter"
require_relative "../errors/too_many_requests_error"
require_relative "../aspects/prometheus_aspect"
require_relative "../aspects/logging_aspect"
require_relative "../aspects/cache_aspect"

##
# Class responsible for providing a default
# webserver.
class Server
  prepend CacheAspect
  prepend LoggingAspect
  prepend PrometheusAspect
  # rubocop:disable Metrics/ParameterLists

  ##
  # Create a new instance of Server.
  # @param {Macaw} macaw
  # @param {Logger} logger
  # @param {Integer} port
  # @param {String} bind
  # @param {Integer} num_threads
  # @param {CachingMiddleware} cache
  # @param {Prometheus::Client:Registry} prometheus
  # @return {Server}
  def initialize(macaw, endpoints_to_cache = nil, cache = nil, prometheus = nil, prometheus_mw = nil)
    @port = macaw.port
    @bind = macaw.bind
    @macaw = macaw
    @macaw_log = macaw.macaw_log
    @num_threads = macaw.threads
    @work_queue = Queue.new
    if @macaw.config&.dig("macaw", "rate_limiting")
      ignored_headers = @macaw.config["macaw"]["rate_limiting"]["ignore_headers"] || []
      @rate_limit = RateLimiterMiddleware.new(
        @macaw.config["macaw"]["rate_limiting"]["window"].to_i || 1,
        @macaw.config["macaw"]["rate_limiting"]["max_requests"].to_i || 60
      )
    end
    @rate_limit ||= nil
    ignored_headers ||= nil
    @cache = { cache: cache, endpoints_to_cache: endpoints_to_cache || [], ignored_headers: ignored_headers }
    @prometheus = prometheus
    @prometheus_middleware = prometheus_mw
    @workers = []
  end

  # rubocop:enable Metrics/ParameterLists

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
    raise TooManyRequestsError unless @rate_limit.nil? || @rate_limit.allow?(client.peeraddr[3])

    client_data = get_client_data(body, headers, parameters)

    @macaw_log.info("Running #{path.gsub("\n", "").gsub("\r", "")}")
    message, status, response_headers = call_endpoint(@prometheus_middleware, @macaw_log, @cache,
                                                      method_name, client_data)
    status ||= 200
    message ||= nil
    response_headers ||= nil
    client.puts ResponseDataFilter.mount_response(status, response_headers, message)
  rescue TooManyRequestsError
    client.print "HTTP/1.1 429 Too Many Requests\r\n\r\n"
  rescue EndpointNotMappedError
    client.print "HTTP/1.1 404 Not Found\r\n\r\n"
  rescue StandardError => e
    client.print "HTTP/1.1 500 Internal Server Error\r\n\r\n"
    @macaw_log.info("Error: #{e}")
  ensure
    client.close
  end

  def call_endpoint(name, client_data)
    @macaw.send(
      name.to_sym,
      { headers: client_data[:headers], body: client_data[:body], params: client_data[:parameters] }
    )
  end

  def get_client_data(body, headers, parameters)
    { body: body, headers: headers, parameters: parameters }
  end
end
