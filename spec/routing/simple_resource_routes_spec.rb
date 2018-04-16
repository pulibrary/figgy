# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Simple Resource Routes" do
  it "routes nested record creates appropriately" do
    expect(get("/concern/simple_resources/1/new")).to route_to("simple_resources#new", parent_id: "1")
    expect(get(parent_new_simple_resource_path(parent_id: "1"))).to route_to("simple_resources#new", parent_id: "1")
    expect(get("/concern/simple_resources/1/manifest")).to route_to("simple_resources#manifest", id: "1", format: :json)
  end
end
