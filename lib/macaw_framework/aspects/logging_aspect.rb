# frozen_string_literal: true

require 'logger'
require_relative '../data_filters/log_data_filter'

##
# This Aspect is responsible for logging
# the input and output of every endpoint called
# in the framework.
module LoggingAspect
  def call_endpoint(logger, *args, **kwargs)
    return super(*args, **kwargs) if logger.nil?

    endpoint_name = args[1]
    client_data   = args[2]

    logger.info("Calling endpoint: #{endpoint_name} | " \
                "params: #{LogDataFilter.sanitize_for_logging(client_data[:params].to_s)} | " \
                "body: #{LogDataFilter.sanitize_for_logging(client_data[:body])}")

    begin
      response = super(*args, **kwargs)
    rescue StandardError => e
      logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end

    logger.info("Response from endpoint: #{endpoint_name} | status: #{response&.dig(1)}")

    response
  end
end
