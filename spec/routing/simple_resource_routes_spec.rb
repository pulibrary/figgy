# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Simple Resource Routes" do
  it "can be created from a 'new' route" do
    expect(get("/concern/scanned_resources/new/simple")).to route_to("scanned_resources#new", change_set: "simple")
  end
end
