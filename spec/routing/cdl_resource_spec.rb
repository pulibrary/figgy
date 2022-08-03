# frozen_string_literal: true
require "rails_helper"

RSpec.describe "CDL Resource Routes" do
  it "can be created from a 'new' route" do
    expect(get("/concern/scanned_resources/new/cdl_resource")).to route_to("scanned_resources#new", change_set: "CDL::Resource")
  end
  it "can be charged" do
    expect(post("/cdl/92260856-c74d-4e7c-bf95-725ce1b2de1a/charge")).to route_to(controller: "cdl/cdl", action: "charge", id: "92260856-c74d-4e7c-bf95-725ce1b2de1a")
  end
end
