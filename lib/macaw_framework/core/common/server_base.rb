# frozen_string_literal: true

require_relative '../../middlewares/memory_invalidation_middleware'
require_relative '../../middlewares/rate_limiter_middleware'
require_relative '../../data_filters/response_data_filter'
require_relative '../../errors/too_many_requests_error'
require_relative '../../utils/supported_ssl_versions'
require_relative '../../aspects/prometheus_aspect'
require_relative '../../aspects/logging_aspect'
require_relative '../../aspects/cache_aspect'
require 'securerandom'

##
# Base module for Server classes. It contains
# methods for client handling, error handling,
# set features and every method that is common
# for the implementations of Servers.
module ServerBase
  prepend CacheAspect
  prepend LoggingAspect
  prepend PrometheusAspect

  private

  def call_endpoint(name, client_data, session_id, _client_ip)
    @macaw.send(
      name.to_sym,
      {
        headers: client_data[:headers],
        body: client_data[:body],
        params: client_data[:params],
        client: @session[session_id][0]
      }
    )
  end

  def get_client_data(body, headers, parameters)
    { body: body, headers: headers, params: parameters }
  end

  def handle_client(client)
    path, method_name, headers, body, parameters = RequestDataFiltering.parse_request_data(client, @macaw.routes)
    raise EndpointNotMappedError unless @macaw.respond_to?(method_name)
    raise TooManyRequestsError unless @rate_limit.nil? || @rate_limit.allow?(client.peeraddr[3])

    client_data = get_client_data(body, headers, parameters)
    session_id = declare_client_session(client_data[:headers], @macaw.secure_header) if @macaw.session

    @macaw_log&.info("Running #{path.gsub("\n", '').gsub("\r", '')}")
    message, status, response_headers = call_endpoint(@prometheus_middleware, @macaw_log, @cache,
                                                      method_name, client_data, session_id, client.peeraddr[3])
    response_headers ||= {}
    response_headers[@macaw.secure_header] = session_id if @macaw.session
    status ||= 200
    message ||= nil
    response_headers ||= nil
    client.puts ResponseDataFilter.mount_response(status, response_headers, message)
  rescue IOError, Errno::EPIPE => e
    @macaw_log&.error("Error writing to client: #{e.message}")
  rescue TooManyRequestsError
    client.print "HTTP/1.1 429 Too Many Requests\r\n\r\n"
  rescue EndpointNotMappedError
    client.print "HTTP/1.1 404 Not Found\r\n\r\n"
  rescue StandardError => e
    client.print "HTTP/1.1 500 Internal Server Error\r\n\r\n"
    @macaw_log&.error(e.full_message)
  ensure
    begin
      client.close
    rescue IOError => e
      @macaw_log&.error("Error closing client: #{e.message}")
    end
  end

  def declare_client_session(headers, secure_header_name)
    session_id = headers[secure_header_name] || SecureRandom.uuid
    session_id = SecureRandom.uuid if @session[session_id].nil?
    @session[session_id] ||= [{}, Time.now]
    session_id
  end

  def set_rate_limiting
    return unless @macaw.config&.dig('macaw', 'rate_limiting')

    @rate_limit = RateLimiterMiddleware.new(
      @macaw.config['macaw']['rate_limiting']['window'].to_i || 1,
      @macaw.config['macaw']['rate_limiting']['max_requests'].to_i || 60
    )
  end

  def set_ssl
    ssl_config = @macaw.config['macaw']['ssl'] if @macaw.config&.dig('macaw', 'ssl')
    ssl_config ||= nil
    unless ssl_config.nil?
      version_config = { min: ssl_config['min'], max: ssl_config['max'] }
      @context = OpenSSL::SSL::SSLContext.new
      @context.min_version = SupportedSSLVersions::VERSIONS[version_config[:min]] unless version_config[:min].nil?
      @context.max_version = SupportedSSLVersions::VERSIONS[version_config[:max]] unless version_config[:max].nil?
      @context.cert = OpenSSL::X509::Certificate.new(File.read(ssl_config['cert_file_name']))

      if ssl_config['key_type'] == 'RSA' || ssl_config['key_type'].nil?
        @context.key = OpenSSL::PKey::RSA.new(File.read(ssl_config['key_file_name']))
      elsif ssl_config['key_type'] == 'EC'
        @context.key = OpenSSL::PKey::EC.new(File.read(ssl_config['key_file_name']))
      else
        raise ArgumentError, "Unsupported SSL/TLS key type: #{ssl_config['key_type']}"
      end
    end
    @context ||= nil
  rescue IOError => e
    @macaw_log&.error("It was not possible to read files #{@macaw.config['macaw']['ssl']['cert_file_name']} and
#{@macaw.config['macaw']['ssl']['key_file_name']}. Please assure the files exist and their names are correct.")
    @macaw_log&.error(e.backtrace)
    raise e
  end

  def set_session
    return unless @macaw.session

    @session ||= {}
    inv = if @macaw.config&.dig('macaw', 'session', 'invalidation_time')
            MemoryInvalidationMiddleware.new(@macaw.config['macaw']['session']['invalidation_time'])
          else
            MemoryInvalidationMiddleware.new
          end
    inv.cache = @session
  end

  def set_features
    @is_shutting_down = false
    set_rate_limiting
    set_session
    set_ssl
  end
end
