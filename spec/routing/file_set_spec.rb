# frozen_string_literal: true
require "rails_helper"

RSpec.describe "FileSet Routes" do
  describe "Caption Routes" do
    it "can route to a caption form" do
      expect(get("/concern/file_sets/92260856-c74d-4e7c-bf95-725ce1b2de1a/file_metadata/new/caption")).to route_to(
        controller: "file_metadata",
        action: "new",
        change_set: "caption",
        file_set_id: "92260856-c74d-4e7c-bf95-725ce1b2de1a"
      )
    end
  end
end
