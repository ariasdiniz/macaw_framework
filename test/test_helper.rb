# frozen_string_literal: true

require "simplecov"
require "simplecov_json_formatter"

SimpleCov.root(File.join(File.dirname(__FILE__), ".."))
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "macaw_framework"

require "minitest/autorun"
