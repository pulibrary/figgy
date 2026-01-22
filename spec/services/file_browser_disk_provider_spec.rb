require "rails_helper"

RSpec.describe FileBrowserDiskProvider do
  describe "#as_json" do
    context "when given a root" do
      it "returns the folders as a file browser compatible JSON" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"])

        expect(provider.as_json).to eq(
          [
            {
              label: "examples",
              path: "examples",
              loadChildrenPath: "/file_browser/disk/default/examples.json",
              entry_type: "default",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            },
            {
              label: "ingest_scratch",
              path: "ingest_scratch",
              loadChildrenPath: "/file_browser/disk/default/ingest_scratch.json",
              entry_type: "default",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            },
            {
              label: "music",
              path: "music",
              loadChildrenPath: "/file_browser/disk/default/music.json",
              entry_type: "default",
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
              loadChildrenPath: "/file_browser/disk/default/numismatics.json",
              entry_type: "default",
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
              loadChildrenPath: "/file_browser/disk/default/studio_new.json",
              entry_type: "default",
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
      it "escapes the load paths" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"], base: "studio_new/DPUL/Santa/ready")

        expect(provider.as_json).to eq(
          [
            {
              label: "991234563506421",
              path: "studio_new/DPUL/Santa/ready/991234563506421",
              loadChildrenPath: "/file_browser/disk/default/#{CGI.escape('studio_new/DPUL/Santa/ready/991234563506421')}.json",
              entry_type: "default",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: false,
              loaded: false,
              children: []
            },
            {
              label: "9917912613506421",
              path: "studio_new/DPUL/Santa/ready/9917912613506421",
              loadChildrenPath: "/file_browser/disk/default/#{CGI.escape('studio_new/DPUL/Santa/ready/9917912613506421')}.json",
              entry_type: "default",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: false,
              loaded: false,
              children: []
            },
            {
              label: "9946093213506421",
              path: "studio_new/DPUL/Santa/ready/9946093213506421",
              loadChildrenPath: "/file_browser/disk/default/#{CGI.escape('studio_new/DPUL/Santa/ready/9946093213506421')}.json",
              entry_type: "default",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            }
          ]
        )
      end

      it "returns the subfolder's entries as JSON" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"], base: "studio_new/DPUL/Santa/ready/991234563506421")

        expect(provider.as_json).to eq(
          [
            {
              label: "01.tif",
              path: "disk://#{Figgy.config['ingest_folder_path']}/studio_new/DPUL/Santa/ready/991234563506421/01.tif",
              expandable: false,
              selectable: true
            },
            {
              label: "02.tif",
              path: "disk://#{Figgy.config['ingest_folder_path']}/studio_new/DPUL/Santa/ready/991234563506421/02.tif",
              expandable: false,
              selectable: true
            }
          ]
        )
      end

      it "doesn't return hidden files" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"], base: "studio_new/DPUL/A123456")

        expect(provider.as_json).to eq([])
      end
      it "doesn't mark empty directories as selectable" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"], base: "studio_new/DPUL")

        expect(provider.as_json.first).to eq(
          {
            label: "A123456",
            path: "studio_new/DPUL/A123456",
            loadChildrenPath: "/file_browser/disk/default/#{CGI.escape('studio_new/DPUL/A123456')}.json",
            entry_type: "default",
            expanded: false,
            expandable: true,
            selected: false,
            selectable: false,
            loaded: false,
            children: []
          }
        )
      end
    end

    context "with a Selene entry" do
      it "marks folders with Selene files and structure as selectable" do
        provider = described_class.new(root: Figgy.config["ingest_folder_path"], base: "studio_new", entry_type: "selene")
        expect(provider.as_json).to eq(
          [
            {
              label: "DPUL",
              path: "studio_new/DPUL",
              loadChildrenPath: "/file_browser/disk/selene/#{CGI.escape('studio_new/DPUL')}.json",
              entry_type: "selene",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: false,
              loaded: false,
              children: []
            },
            {
              label: "selene-example",
              path: "studio_new/selene-example",
              loadChildrenPath: "/file_browser/disk/selene/#{CGI.escape('studio_new/selene-example')}.json",
              entry_type: "selene",
              expanded: false,
              expandable: true,
              selected: false,
              selectable: true,
              loaded: false,
              children: []
            }
          ]
        )
      end
    end
  end
end
