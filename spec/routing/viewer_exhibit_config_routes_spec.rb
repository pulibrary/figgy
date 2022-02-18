# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exhibit Viewer Configuration Routes" do
  it "routes requests for viewer configurations for digital exhibits with a manifest URL" do
    expect(get("/viewer/exhibit/config?manifest=https://manifest-url")).to route_to("application#viewer_exhibit_config", manifest: "https://manifest-url")
  end
end
