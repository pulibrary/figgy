# frozen_string_literal: true
module FigxStubbing
  def stub_figx_collection_manifest
    path = Rails.root.join("spec", "fixtures", "figx", "collection.json")
    stub_request(:get, /http:\/\/localhost:4000\/manifest\/.*/)
      .to_return(status: 200, body: File.open(path), headers: { "Content-Type": "application/json" })
  end
end

RSpec.configure do |config|
  config.include FigxStubbing
end
