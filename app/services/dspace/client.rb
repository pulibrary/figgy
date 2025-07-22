# frozen_string_literal: true
class Dspace::Client
  delegate :get, to: :client
  attr_reader :ark, :dspace_token
  def initialize(ark, dspace_token)
    @ark = ark
    @dspace_token = dspace_token
  end

  def client
    @client ||= Faraday.new(
      "https://dataspace.princeton.edu",
      params: {
        "expand" => "all"
      },
      headers: {
        "rest-dspace-token" => dspace_token
      }
    ) do |builder|
      builder.request :retry, { max: 300, interval: 0.5, interval_randomness: 0.5, backoff_factor: 2 }
      builder.request :json
      builder.response :json
    end
  end

  def bitstream_client
    @bitstream_client ||= Faraday.new(
      "https://dataspace.princeton.edu",
      headers: {
        "rest-dspace-token" => dspace_token
      }
    )
  end

  def resource
    @resource ||= Dspace::Resource.new(response, self)
  end

  def response
    rest_data.body
  end

  def rest_data
    @rest_data ||= client.get("/rest/handle/#{ark}")
  end
end
