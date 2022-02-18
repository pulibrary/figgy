# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Archival Media Collection Routes" do
  it "can be created from a 'new' route" do
    expect(get("/collections/new/archival_media_collection")).to route_to("collections#new", change_set: "archival_media_collection")
  end
end
