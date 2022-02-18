# frozen_string_literal: true

namespace :figgy do
  desc "Installs ASpace access key into .env via lastpass."
  task setup_keys: :environment do
    aspace_json = JSON.parse(`lpass show Shared-ITIMS-Passwords/pulfa/aspace.princeton.edu -j`).first
    figgy_staging_json = JSON.parse(`lpass show Shared-ITIMS-Passwords/Figgy/FiggyStagingAWS -j`).first

    File.open(".env", "w") do |f|
      f.puts "ASPACE_URL=https://aspace-staging.princeton.edu/staff/api"
      f.puts "ASPACE_USER=#{aspace_json["username"]}"
      f.puts "ASPACE_PASSWORD=#{aspace_json["password"]}"
      f.puts "FIGGY_CLOUD_GEO_BUCKET=figgy-geo-staging"
      f.puts "FIGGY_AWS_ACCESS_KEY_ID=#{figgy_staging_json["username"]}"
      f.puts "FIGGY_AWS_SECRET_ACCESS_KEY=#{figgy_staging_json["password"]}"
    end
    puts "Generated .env file"
  end
end
