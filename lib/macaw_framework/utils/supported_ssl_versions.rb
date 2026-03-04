# frozen_string_literal: true

require 'openssl'

module SupportedSSLVersions
  VERSIONS = {
    'TLS1.1' => OpenSSL::SSL::TLS1_1_VERSION,
    'TLS1.2' => OpenSSL::SSL::TLS1_2_VERSION,
    'TLS1.3' => OpenSSL::SSL::TLS1_3_VERSION
  }.freeze
end
