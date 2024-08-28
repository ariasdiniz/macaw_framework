# frozen_string_literal: true

##
# Error raised when the client calls
# for a path that doesn't exist.
class EndpointNotMappedError < StandardError
  def initialize(msg = 'Undefined endpoint')
    super
  end
end
