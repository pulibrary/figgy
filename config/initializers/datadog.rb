require_relative "figgy"
Datadog.configure do |c|
  c.env = Rails.env.to_s
  c.service = "figgy"
end
