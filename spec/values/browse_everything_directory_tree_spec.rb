# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrowseEverythingDirectoryTree do
  describe "#ingest_ids" do
    # Many Single Volumes
    # - Lapidus
    #  - 123456
    #    page1
    #  - 1234567
    #    page1
    context "many single volumes" do
      it "returns children of the root" do
        tree = described_class.new(
          [
            "/lapidus",
            "/lapidus/123456",
            "/lapidus/1234567"
          ]
        )

        expect(tree.tree).to eq(
          "/lapidus" =>
           [
             { "/lapidus/123456" => [] },
             { "/lapidus/1234567" => [] }
           ]
        )

        expect(tree.ingest_ids).to eq ["/lapidus/123456", "/lapidus/1234567"]
      end
    end
  end
end
