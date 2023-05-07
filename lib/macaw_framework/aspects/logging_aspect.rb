# frozen_string_literal: false

require "logger"

##
# This Aspect is responsible for logging
# the input and output of every endpoint called
# in the framework.
module LoggingAspect
  def call_endpoint(logger, *args)
    endpoint_name = args[1].split(".")[1..].join("/")
    logger.info("Request received for #{endpoint_name} with arguments: #{args[2..]}")

    begin
      response = super(*args)
      logger.info("Response for #{endpoint_name}: #{response}")
    rescue StandardError => e
      logger.error("Error processing #{endpoint_name}: #{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end

    response
  end
end
