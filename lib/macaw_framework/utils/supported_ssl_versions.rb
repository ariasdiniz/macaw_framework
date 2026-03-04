# frozen_string_literal: true

require 'openssl'

module SupportedSSLVersions
  # SSL2 and SSL3 are cryptographically broken (POODLE, DROWN) and removed.
  # TLS 1.1 is deprecated by RFC 8996; prefer TLS 1.2 or TLS 1.3.
  VERSIONS = {
    'TLS1.1' => OpenSSL::SSL::TLS1_1_VERSION,
    'TLS1.2' => OpenSSL::SSL::TLS1_2_VERSION,
    'TLS1.3' => OpenSSL::SSL::TLS1_3_VERSION
  }.freeze
end
