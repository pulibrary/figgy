# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Viewer Configuration Routes" do
  it "routes requests for viewer configurations with a resource ID" do
    expect(get("/viewer/config/resource-id")).to route_to("application#viewer_config", id: "resource-id")
  end
end
