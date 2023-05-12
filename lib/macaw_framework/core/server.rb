# frozen_string_literal: true

require_relative "../middlewares/memory_invalidation_middleware"
require_relative "../middlewares/rate_limiter_middleware"
require_relative "../data_filters/response_data_filter"
require_relative "../errors/too_many_requests_error"
require_relative "../utils/supported_ssl_versions"
require_relative "../aspects/prometheus_aspect"
require_relative "../aspects/logging_aspect"
require_relative "../aspects/cache_aspect"
require "openssl"

##
# Class responsible for providing a default
# webserver.
class Server
  prepend CacheAspect
  prepend LoggingAspect
  prepend PrometheusAspect
  # rubocop:disable Metrics/ParameterLists

  attr_reader :context

  ##
  # Create a new instance of Server.
  # @param {Macaw} macaw
  # @param {Logger} logger
  # @param {Integer} port
  # @param {String} bind
  # @param {Integer} num_threads
  # @param {MemoryInvalidationMiddleware} cache
  # @param {Prometheus::Client:Registry} prometheus
  # @return {Server}
  def initialize(macaw, endpoints_to_cache = nil, cache = nil, prometheus = nil, prometheus_mw = nil)
    @port = macaw.port
    @bind = macaw.bind
    @macaw = macaw
    @macaw_log = macaw.macaw_log
    @num_threads = macaw.threads
    @work_queue = Queue.new
    ignored_headers = set_cache_ignored_h
    set_features
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
    @server = OpenSSL::SSL::SSLServer.new(@server, @context) if @context
    @workers_mutex = Mutex.new
    @num_threads.times do
      spawn_worker
    end

    Thread.new do
      loop do
        sleep 10
        maintain_worker_pool
      end
    end

    loop do
      @work_queue << @server.accept
    rescue OpenSSL::SSL::SSLError => e
      @macaw_log.error("SSL error: #{e.message}")
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

    declare_client_session(client)
    client_data = get_client_data(body, headers, parameters)

    @macaw_log.info("Running #{path.gsub("\n", "").gsub("\r", "")}")
    message, status, response_headers = call_endpoint(@prometheus_middleware, @macaw_log, @cache,
                                                      method_name, client_data, client.peeraddr[3])
    status ||= 200
    message ||= nil
    response_headers ||= nil
    client.puts ResponseDataFilter.mount_response(status, response_headers, message)
  rescue IOError, Errno::EPIPE => e
    @macaw_log.error("Error writing to client: #{e.message}")
  rescue TooManyRequestsError
    client.print "HTTP/1.1 429 Too Many Requests\r\n\r\n"
  rescue EndpointNotMappedError
    client.print "HTTP/1.1 404 Not Found\r\n\r\n"
  rescue StandardError => e
    client.print "HTTP/1.1 500 Internal Server Error\r\n\r\n"
    @macaw_log.info("Error: #{e}")
  ensure
    begin
      client.close
    rescue IOError => e
      @macaw_log.error("Error closing client: #{e.message}")
    end
  end

  def declare_client_session(client)
    @session[client.peeraddr[3]] ||= [{}, Time.now]
    @session[client.peeraddr[3]] = [{}, Time.now] if @session[client.peeraddr[3]][0].nil?
  end

  def set_rate_limiting
    return unless @macaw.config&.dig("macaw", "rate_limiting")

    @rate_limit = RateLimiterMiddleware.new(
      @macaw.config["macaw"]["rate_limiting"]["window"].to_i || 1,
      @macaw.config["macaw"]["rate_limiting"]["max_requests"].to_i || 60
    )
  end

  def set_cache_ignored_h
    return unless @macaw.config&.dig("macaw", "cache", "ignore_headers")

    @macaw.config["macaw"]["cache"]["ignore_headers"] || []
  end

  def set_ssl
    ssl_config = @macaw.config["macaw"]["ssl"] if @macaw.config&.dig("macaw", "ssl")
    ssl_config ||= nil
    unless ssl_config.nil?
      version_config = { min: ssl_config["min"], max: ssl_config["max"] }
      @context = OpenSSL::SSL::SSLContext.new
      @context.min_version = SupportedSSLVersions::VERSIONS[version_config[:min]] unless version_config[:min].nil?
      @context.max_version = SupportedSSLVersions::VERSIONS[version_config[:max]] unless version_config[:max].nil?
      @context.cert = OpenSSL::X509::Certificate.new(File.read(ssl_config["cert_file_name"]))
      @context.key = OpenSSL::PKey::RSA.new(File.read(ssl_config["key_file_name"]))
    end
    @context ||= nil
  rescue IOError => e
    @macaw_log.error("It was not possible to read files #{@macaw.config["macaw"]["ssl"]["cert_file_name"]} and
#{@macaw.config["macaw"]["ssl"]["key_file_name"]}. Please assure the files exists and their names are correct.")
    @macaw_log.error(e.backtrace)
    raise e
  end

  def set_session
    @session = {}
    inv = if @macaw.config&.dig("macaw", "session", "invalidation_time")
            MemoryInvalidationMiddleware.new(@macaw.config["macaw"]["session"]["invalidation_time"])
          else
            MemoryInvalidationMiddleware.new
          end
    inv.cache = @session
  end

  def set_features
    set_rate_limiting
    set_session
    set_ssl
  end

  def call_endpoint(name, client_data, client_ip)
    @macaw.send(
      name.to_sym,
      {
        headers: client_data[:headers],
        body: client_data[:body],
        params: client_data[:params],
        client: @session[client_ip][0]
      }
    )
  end

  def get_client_data(body, headers, parameters)
    { body: body, headers: headers, params: parameters }
  end

  def spawn_worker
    @workers_mutex.synchronize do
      @workers << Thread.new do
        loop do
          client = @work_queue.pop
          break if client == :shutdown

          handle_client(client)
        end
      end
    end
  end

  def maintain_worker_pool
    @workers_mutex.synchronize do
      @workers.each_with_index do |worker, index|
        unless worker.alive?
          @macaw_log.error("Worker thread #{index} died, respawning...")
          @workers[index] = spawn_worker
        end
      end
    end
  end
end
