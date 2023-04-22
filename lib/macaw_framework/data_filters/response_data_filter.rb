# frozen_string_literal: true

require_relative "../utils/http_status_code"

##
# Module responsible to filter and mount HTTP responses
module ResponseDataFilter
  include HttpStatusCode

  def self.mount_response(status, headers, body)
    "#{mount_first_response_line(status, headers)}#{mount_response_headers(headers)}#{body}"
  end

  def self.mount_first_response_line(status, headers)
    separator = " \r\n\r\n"
    separator = " \r\n" unless headers.nil?

    "HTTP/1.1 #{status} #{HTTP_STATUS_CODE_MAP[status]}#{separator}"
  end

  def self.mount_response_headers(headers)
    return nil if headers.nil?

    response = ""
    headers.each do |key, value|
      response += "#{key}: #{value}\r\n"
    end
    response += "\r\n\r\n"
    response
  end
end
