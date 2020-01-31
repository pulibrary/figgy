# frozen_string_literal: true
if Rails.env.development? || Rails.env.test?
  begin
    lando_services = JSON.parse(`lando info --format json`, symbolize_names: true)
    lando_services.each do |service|
      service[:external_connection]&.each do |key, value|
        ENV["lando_#{service[:service]}_conn_#{key}"] = value
      end
      next unless service[:creds]
      service[:creds].each do |key, value|
        ENV["lando_#{service[:service]}_creds_#{key}"] = value
      end
    end
  rescue StandardError
    nil
  end
end
