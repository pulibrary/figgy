# frozen_string_literal: true

require "io/console"

namespace :figgy do
  namespace :dspace do
    desc "Request a DSpace REST API Token."
    task request_token: :environment do
      dspace_user = ENV["DSPACE_API_USER"]
      abort "usage: rake figgy:dspace:request_token DSPACE_API_USER=user@princeton.edu" unless dspace_user

      puts "Please enter the password for #{dspace_user}: "
      dspace_password = STDIN.noecho(&:gets).chomp

      rest_base_url = "https://dataspace.princeton.edu/rest"

      headers = {
        "Content-Type": "application/json"
      }
      conn = Faraday.new(
        url: rest_base_url,
        headers: headers
      )

      path = "login"
      params = {
        "email": dspace_user,
        "password": dspace_password
      }
      response = conn.post(path, params.to_json)
      dspace_token = response.body

      @logger = Logger.new(STDOUT)
      @logger.info "API token for #{dspace_user}: #{dspace_token}"
    end

    desc "Verify the status of a DSpace REST API Token."
    task verify_token: :environment do
      dspace_api_token = ENV["DSPACE_API_TOKEN"]
      abort "usage: rake figgy:dspace:verify_token DSPACE_API_TOKEN=secret" unless dspace_api_token

      rest_base_url = "https://dataspace.princeton.edu/rest"

      headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "rest-dspace-token": dspace_api_token
      }
      conn = Faraday.new(
        url: rest_base_url,
        headers: headers
      )

      path = "status"
      response = conn.get(path)
      json_response = JSON.parse(response.body)

      @logger = Logger.new(STDOUT)
      @logger.info "Status for API token: #{json_response}"
    end
  end
end
