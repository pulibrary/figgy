# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileBrowserDiskProvider do
  describe "#as_json" do
    context "when given a root" do
      it "returns the folders as a file browser compatible JSON" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"])

        expect(provider.as_json).to eq(
          [
            {
              label: "music",
              path: "music",
              loadChildrenPath: "/file_browser/disk/music.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            },
            {
              label: "numismatics",
              path: "numismatics",
              loadChildrenPath: "/file_browser/disk/numismatics.json",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            },
            {
              label: "studio_new",
              path: "studio_new",
              loadChildrenPath: "/file_browser/disk/studio_new.json",
              expanded: false,
              expandable: true,
              selected: false,
              # This is arguable - right now true because there are only
              # directories as children.
              selectable: true,
              loaded: false,
              children: []
            }
          ]
        )
      end
    end
    context "when given a root and base" do
      it "returns the subfolder's entries as JSON" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"], base: "studio_new/DPUL/Santa/ready/123456")

        expect(provider.as_json).to eq(
          [
            {
              label: "01.tif",
              path: "disk://#{Figgy.config['ingest_folder_path']}/studio_new/DPUL/Santa/ready/123456/01.tif",
              expandable: false,
              selectable: true
            },
            {
              label: "02.tif",
              path: "disk://#{Figgy.config['ingest_folder_path']}/studio_new/DPUL/Santa/ready/123456/02.tif",
              expandable: false,
              selectable: true
            }
          ]
        )
      end
    end
  end
end
