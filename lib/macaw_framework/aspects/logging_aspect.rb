# frozen_string_literal: true

require "logger"

##
# This Aspect is responsible for logging
# the input and output of every endpoint called
# in the framework.
module LoggingAspect
  def call_endpoint(logger, *args)
    logger.info("Request received for #{args[1]} with arguments: #{args}")

    begin
      response = super(*args)
      logger.info("Response for #{args[1]}: #{response}")
    rescue StandardError => e
      logger.error("Error processing #{args[1]}: #{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end

    response
  end
end
