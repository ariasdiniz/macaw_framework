# frozen_string_literal: false

require 'logger'
require_relative '../data_filters/log_data_filter'

##
# This Aspect is responsible for logging
# the input and output of every endpoint called
# in the framework.
module LoggingAspect
  def call_endpoint(logger, *args)
    return super(*args) if logger.nil?

    endpoint_name = args[1].split('.')[1..].join('/')
    logger.info("Request received for [#{endpoint_name}] from [#{args[-1]}]")

    begin
      response = super(*args)
    rescue StandardError => e
      logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end

    response
  end
end
