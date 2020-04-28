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
    context "many single volumes with parent" do
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
          {
            "/lapidus/123456" => {},
            "/lapidus/1234567" => {}
          }
        )

        expect(tree.ingest_ids).to eq ["/lapidus/123456", "/lapidus/1234567"]
      end
    end

    #  - 123456
    #    page1
    #  - 1234567
    #    page1
    context "many single volumes, no parent" do
      it "returns children of the root" do
        tree = described_class.new(
          [
            "/lapidus/123456",
            "/lapidus/1234567"
          ]
        )

        expect(tree.tree).to eq(
          "/lapidus/123456" => {},
          "/lapidus/1234567" => {}
        )

        expect(tree.ingest_ids).to eq ["/lapidus/123456", "/lapidus/1234567"]
      end
    end

    # Many MVW
    # Lapidus
    #  - 123456
    #    - vol1
    #      - page1
    #    - vol2
    #      - page2
    #  - 1234567
    #    - vol1
    #      - page1
    #    - vol2
    #      - page2
    context "directory of multi-volume works" do
      it "returns children of the root" do
        tree = described_class.new(
          [
            "/multi_volume",
            "/multi_volume/123456",
            "/multi_volume/4609321",
            "/multi_volume/4609321/vol1",
            "/multi_volume/123456/vol1",
            "/multi_volume/4609321/vol2",
            "/multi_volume/123456/vol2"
          ]
        )

        expect(tree.tree).to eq(
          "/multi_volume" =>
          {
            "/multi_volume/123456" => {
              "/multi_volume/123456/vol1" => {},
              "/multi_volume/123456/vol2" => {}
            },
            "/multi_volume/4609321" => {
              "/multi_volume/4609321/vol1" => {},
              "/multi_volume/4609321/vol2" => {}
            }
          }
        )

        expect(tree.ingest_ids).to eq ["/multi_volume/123456", "/multi_volume/4609321"]
      end
    end
  end
end
