# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Routing", type: :routing do
  describe "refresh remote metadata" do
    it "routes post requests with identifiers of metadata to refresh" do
      expect(post("/resources/refresh_remote_metadata")).to route_to("resources#refresh_remote_metadata", format: :json)
    end
  end
end
