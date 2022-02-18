# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CDL Resource Routes" do
  it "can be created from a 'new' route" do
    expect(get("/concern/scanned_resources/new/cdl_resource")).to route_to("scanned_resources#new", change_set: "CDL::Resource")
  end
end
