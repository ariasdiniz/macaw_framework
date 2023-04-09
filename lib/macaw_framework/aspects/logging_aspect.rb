# frozen_string_literal: true

require "logger"

##
# This Aspect is responsible for logging
# the input and output of every endpoint called
# in the framework.
module LoggingAspect
  def call_endpoint(logger, *args)
    logger.info("Input of #{args[0]}: #{args}")
    response = super(*args)
    logger.info("Output of #{args[0]} #{response}")
    response
  end
end
