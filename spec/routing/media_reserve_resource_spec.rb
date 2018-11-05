# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Media Reserve Routes" do
  it "can be created from a 'new' route" do
    expect(get("/concern/scanned_resources/new/media_reserve")).to route_to("scanned_resources#new", change_set: "media_reserve")
  end
end
