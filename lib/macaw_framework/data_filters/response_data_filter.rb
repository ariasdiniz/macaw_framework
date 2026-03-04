# frozen_string_literal: true

require_relative '../utils/http_status_code'

##
# Module responsible to filter and mount HTTP responses
module ResponseDataFilter
  include HttpStatusCode

  def self.mount_response(status, headers, body)
    "#{mount_first_response_line(status, headers)}#{mount_response_headers(headers)}#{body}"
  end

  def self.mount_first_response_line(status, headers)
    reason = HTTP_STATUS_CODE_MAP[status] || 'Unknown'
    separator = headers.nil? ? "\r\n\r\n" : "\r\n"
    "HTTP/1.1 #{status} #{reason}#{separator}"
  end

  def self.mount_response_headers(headers)
    return '' if headers.nil?

    response = +''
    headers.each do |key, value|
      response << "#{key}: #{value}\r\n"
    end
    response << "\r\n"
    response
  end
end
