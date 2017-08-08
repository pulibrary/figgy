# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Scanned Resource Routes" do
  it "routes nested record creates appropriately" do
    expect(get("/concern/scanned_resources/1/new")).to route_to("scanned_resources#new", parent_id: "1")
    expect(get(parent_new_scanned_resource_path(parent_id: "1"))).to route_to("scanned_resources#new", parent_id: "1")
  end
end
