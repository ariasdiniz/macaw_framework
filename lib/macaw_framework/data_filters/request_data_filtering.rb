# frozen_string_literal: true

require_relative '../errors/endpoint_not_mapped_error'

##
# Module containing methods to filter Strings
module RequestDataFiltering
  VARIABLE_PATTERN = %r{:[^/]+}

  ##
  # Method responsible for extracting information
  # provided by the client like Headers and Body
  def self.parse_request_data(client, routes)
    path, parameters = extract_url_parameters(client.gets&.gsub('HTTP/1.1', ''))
    parameters = {} if parameters.nil?

    method_name = sanitize_method_name(path)
    method_name = select_path(method_name, routes, parameters)
    body_first_line, headers = extract_headers(client)
    body = extract_body(client, body_first_line, headers['Content-Length'].to_i)
    [path, method_name, headers, body, parameters]
  end

  def self.select_path(method_name, routes, parameters)
    return method_name if routes.include?(method_name)

    selected_route = nil
    routes.each do |route|
      split_route = route&.split('.')
      split_name = method_name&.split('.')

      next unless split_route&.length == split_name&.length
      next unless match_path_with_route(split_name, split_route)

      selected_route = route
      split_route&.each_with_index do |var, index|
        parameters[var[1..].to_sym] = split_name&.dig(index) if var =~ VARIABLE_PATTERN
      end
      break
    end

    raise EndpointNotMappedError if selected_route.nil?

    selected_route
  end

  def self.match_path_with_route(split_path, split_route)
    split_route&.each_with_index do |var, index|
      return false if var != split_path[index] && !var.match?(VARIABLE_PATTERN)
    end

    true
  end

  ##
  # Method responsible for sanitizing the method name
  def self.sanitize_method_name(path)
    path = extract_path(path)
    method_name = path&.gsub('/', '.')&.strip&.downcase
    method_name&.gsub!(' ', '')
    method_name
  end

  ##
  # Method responsible for extracting the path from URI
  def self.extract_path(path)
    return path if path.nil?

    path[0] == '/' ? path[1..].gsub('/', '.') : path.gsub('/', '.')
  end

  ##
  # Method responsible for extracting the headers from request
  def self.extract_headers(client)
    header = client.gets&.delete("\n")&.delete("\r")
    headers = {}
    while header&.match(%r{[a-zA-Z0-9\-/*]*: [a-zA-Z0-9\-/*]})
      split_header = header.split(':')
      headers[split_header[0].strip] = split_header[1].strip
      header = client.gets&.delete("\n")&.delete("\r")
    end
    [header, headers]
  end

  ##
  # Method responsible for extracting the body from request
  def self.extract_body(client, body_first_line, content_length)
    body = client&.read(content_length)
    body_first_line << body.to_s
  end

  ##
  # Method responsible for extracting the parameters from URI
  def self.extract_url_parameters(http_first_line)
    return http_first_line, nil unless http_first_line =~ /\?/

    path_and_parameters = http_first_line.split('?', 2)
    path = "#{path_and_parameters[0]} "
    parameters_array = path_and_parameters[1].split('&')
    parameters_array.map! do |item|
      split_item = item.split('=')
      { sanitize_parameter_name(split_item[0]) => sanitize_parameter_value(split_item[1]) }
    end
    parameters = {}
    parameters_array.each { |item| parameters.merge!(item) }
    [path, parameters]
  end

  ##
  # Method responsible for sanitizing the parameter name
  def self.sanitize_parameter_name(name)
    name&.gsub(/[^\w\s]/, '')
  end

  ##
  # Method responsible for sanitizing the parameter value
  def self.sanitize_parameter_value(value)
    value&.gsub(/[^\w\s]/, '')
    value&.gsub(/\s/, '')
  end
end
