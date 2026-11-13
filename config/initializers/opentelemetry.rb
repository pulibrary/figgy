# Do not run OTel in dev or test
if Rails.env.production? || Rails.env.staging?
  require "opentelemetry/sdk"
  require "opentelemetry/instrumentation/all"
  require "opentelemetry-exporter-otlp"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = "figgy"
    c.use_all() # enables all instrumentation
  end
end
