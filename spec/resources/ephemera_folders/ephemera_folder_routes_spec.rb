# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ephemera Folder Routes", type: :routing do
  it "routes nested record creates appropriately" do
    expect(get("/concern/ephemera_projects/1/ephemera_folders/new")).to route_to("ephemera_folders#new", parent_id: "1")
    expect(get("/concern/ephemera_boxes/2/ephemera_folders/new")).to route_to("ephemera_folders#new", parent_id: "2")
  end
end
