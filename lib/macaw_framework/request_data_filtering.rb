# frozen_string_literal: true

##
# Module containing methods to filter Strings
module RequestDataFiltering
  ##
  # Method responsible for extracting information
  # provided by the client like Headers and Body
  def self.extract_client_info(client)
    path, parameters = extract_url_parameters(client.gets.gsub("HTTP/1.1", ""))
    method_name = sanitize_method_name(path)
    body_first_line, headers = extract_headers(client)
    body = extract_body(client, body_first_line, headers["Content-Length"].to_i)
    [path, method_name, headers, body, parameters]
  end

  ##
  # Method responsible for sanitizing the method name
  def self.sanitize_method_name(path)
    path = extract_path(path)
    method_name = path.gsub("/", "_").strip.downcase
    method_name.gsub!(" ", "")
    method_name
  end

  ##
  # Method responsible for extracting the path from URI
  def self.extract_path(path)
    path[0] == "/" ? path[1..].gsub("/", "_") : path.gsub("/", "_")
  end

  ##
  # Method responsible for extracting the headers from request
  def self.extract_headers(client)
    header = client.gets.delete("\n").delete("\r")
    headers = {}
    while header.match(%r{[a-zA-Z0-9\-/*]*: [a-zA-Z0-9\-/*]})
      split_header = header.split(":")
      headers[split_header[0].strip] = split_header[1].strip
      header = client.gets.delete("\n").delete("\r")
    end
    [header, headers]
  end

  ##
  # Method responsible for extracting the body from request
  def self.extract_body(client, body_first_line, content_length)
    body = client.read(content_length)
    body_first_line << body.to_s
  end

  ##
  # Method responsible for extracting the parameters from URI
  def self.extract_url_parameters(http_first_line)
    return http_first_line, nil unless http_first_line =~ /\?/

    path_and_parameters = http_first_line.split("?", 2)
    path = "#{path_and_parameters[0]} "
    parameters_array = path_and_parameters[1].split("&")
    parameters_array.map! do |item|
      split_item = item.split("=")
      { sanitize_parameter_name(split_item[0]) => sanitize_parameter_value(split_item[1]) }
    end
    parameters = {}
    parameters_array.each { |item| parameters.merge!(item) }
    [path, parameters]
  end

  ##
  # Method responsible for sanitizing the parameter name
  def self.sanitize_parameter_name(name)
    name.gsub(/[^\w\s]/, "")
  end

  ##
  # Method responsible for sanitizing the parameter value
  def self.sanitize_parameter_value(value)
    value.gsub(/[^\w\s]/, "")
    value.gsub(/[\r\n\s]/, "")
  end
end
