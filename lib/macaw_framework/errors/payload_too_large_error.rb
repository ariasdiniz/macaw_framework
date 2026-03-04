# frozen_string_literal: true

##
# Error raised when the request body exceeds the configured max_body_size.
class PayloadTooLargeError < StandardError; end
