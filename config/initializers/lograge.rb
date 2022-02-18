# frozen_string_literal: true

require "lograge/sql/extension"
Rails.application.configure do
  # Lograge config
  config.lograge.enabled = true

  # We are asking here to log in RAW (which are actually ruby hashes). The Ruby logging is going to take care of the JSON formatting.
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  # This is is useful if you want to log query parameters
  config.lograge.custom_options = lambda do |event|
    {ddsource: ["ruby"],
     params: event.payload[:params].reject { |k| %w[controller action].include? k }}
  end
  Lograge::ActiveRecordLogSubscriber.attach_to :sequel
end
