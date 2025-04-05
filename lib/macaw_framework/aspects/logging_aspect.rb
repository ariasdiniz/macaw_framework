# frozen_string_literal: false

require 'logger'
require_relative '../data_filters/log_data_filter'

##
# This Aspect is responsible for logging
# the input and output of every endpoint called
# in the framework.
module LoggingAspect
  def call_endpoint(logger, *args, **kwargs)
    return super(*args, **kwargs) if logger.nil?

    begin
      response = super(*args)
    rescue StandardError => e
      logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end

    response
  end
end
