# frozen_string_literal: true

# Load the C extension when available (built via `rake compile` or `gem install`).
# Falls back transparently to pure-Ruby mode if the extension has not been compiled.
begin
  require 'macaw_framework_ext'
rescue LoadError
  nil
end

##
# Main module for all Macaw classes
module MacawFramework; end

require_relative 'macaw_framework/macaw'
require_relative 'macaw_framework/cache'
