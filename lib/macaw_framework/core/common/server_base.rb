# frozen_string_literal: true

require_relative '../../middlewares/memory_invalidation_middleware'
require_relative '../../data_filters/response_data_filter'
require_relative '../../utils/supported_ssl_versions'
require_relative '../../aspects/logging_aspect'
require_relative '../../aspects/cache_aspect'

##
# Base module for Server classes. It contains
# methods for client handling, error handling,
# set features and every method that is common
# for the implementations of Servers.
module ServerBase
  prepend CacheAspect
  prepend LoggingAspect

  private

  def call_endpoint(name, client_data)
    @macaw.send(
      name.to_sym,
      {
        headers: client_data[:headers],
        body: client_data[:body],
        params: client_data[:params]
      }
    )
  end

  def get_client_data(body, headers, parameters)
    { body: body, headers: headers, params: parameters }
  end

  def handle_client(client)
    apply_socket_timeout(client)
    loop do
      _path, method_name, headers, body, parameters = RequestDataFiltering.parse_request_data(client, @macaw.routes)
      raise EndpointNotMappedError unless @macaw.respond_to?(method_name)

      keep_alive = keep_alive_connection?(headers)
      client.write build_response(method_name, headers, body, parameters, keep_alive)
      break unless keep_alive
    rescue Errno::ECONNRESET, Errno::EPIPE, IOError
      break
    rescue EndpointNotMappedError
      client.print "HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n"
      break
    rescue StandardError => e
      client.print "HTTP/1.1 500 Internal Server Error\r\nConnection: close\r\n\r\n"
      @macaw_log&.error(e.full_message)
      break
    end
  ensure
    begin
      client.close
    rescue IOError => e
      @macaw_log&.error("Error closing client: #{e.message}")
    end
  end

  def build_response(method_name, headers, body, parameters, keep_alive)
    client_data = get_client_data(body, headers, parameters)
    message, status, response_headers = call_endpoint(@macaw_log, @cache, method_name, client_data)
    response_headers ||= {}
    status ||= 200
    response_headers['Connection'] = keep_alive ? 'keep-alive' : 'close'
    response_headers['Content-Length'] = message.to_s.bytesize
    ResponseDataFilter.mount_response(status, response_headers, message)
  end

  def apply_socket_timeout(client)
    timeout = @macaw.keep_alive_timeout || 30
    client.timeout = timeout
  rescue NoMethodError
    io = client.respond_to?(:to_io) ? client.to_io : client
    timeval = [timeout, 0].pack('l_2')
    io.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval)
  rescue StandardError
    nil
  end

  def keep_alive_connection?(headers)
    headers['Connection']&.downcase != 'close'
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

  def set_features
    @is_shutting_down = false
    set_ssl
  end
end
