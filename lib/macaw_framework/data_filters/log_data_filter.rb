# frozen_string_literal: false

require "json"

##
# Module responsible for sanitizing log data
module LogDataFilter
  DEFAULT_MAX_LENGTH = 512
  DEFAULT_SENSITIVE_FIELDS = [].freeze

  def self.config
    @config ||= begin
      file_path = "application.json"
      config = {
        max_length: DEFAULT_MAX_LENGTH,
        sensitive_fields: DEFAULT_SENSITIVE_FIELDS
      }

      if File.exist?(file_path)
        json = JSON.parse(File.read(file_path))

        if json["macaw"] && json["macaw"]["log"]
          log_config = json["macaw"]["log"]
          config[:max_length] = log_config["max_length"] if log_config["max_length"]
          config[:sensitive_fields] = log_config["sensitive_fields"] if log_config["sensitive_fields"]
        end
      end

      config
    end
  end

  def self.sanitize_for_logging(data, sensitive_fields: config[:sensitive_fields])
    return "" if data.nil?

    data = data.to_s.force_encoding("UTF-8")
    data = data.slice(0, config[:max_length])
    data = data.gsub("\\", "")

    sensitive_fields.each do |field|
      next unless data.include?(field.to_s)

      data = data.gsub(/(#{Regexp.escape(field.to_s)}\s*[:=]\s*)([^\s]+)/) do |_match|
        "#{::Regexp.last_match(1)}#{Digest::SHA256.hexdigest(::Regexp.last_match(2))}"
      end
    end

    data
  end
end
