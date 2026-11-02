require "rails_helper"

RSpec.describe IngestFolderPath do
  let(:root) { Pathname.new(Figgy.config["ingest_folder_path"]) }
  let(:ingest_folder_path) { described_class.new }

  describe "#resolve" do
    it "resolves relative paths within the ingest folder" do
      expect(ingest_folder_path.resolve("examples/bulk_ingest")).to eq root.join("examples", "bulk_ingest")
    end

    it "resolves absolute paths and disk:// IDs within the ingest folder" do
      path = root.join("examples", "bulk_ingest")

      expect(ingest_folder_path.resolve(path.to_s)).to eq path
      expect(ingest_folder_path.resolve("disk://#{path}")).to eq path
    end

    it "resolves a blank path to the root" do
      expect(ingest_folder_path.resolve("")).to eq root
    end

    it "rejects absolute paths outside the ingest folder" do
      expect { ingest_folder_path.resolve("/etc") }.to raise_error described_class::InvalidPath
      expect { ingest_folder_path.resolve("disk:///etc/hosts") }.to raise_error described_class::InvalidPath
    end

    it "rejects .. traversal out of the ingest folder" do
      expect { ingest_folder_path.resolve("../files/example.tif") }.to raise_error described_class::InvalidPath
      expect { ingest_folder_path.resolve("disk://#{root}/../files/example.tif") }.to raise_error described_class::InvalidPath
    end

    it "rejects sibling folders which share the root as a prefix" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(["#{dir}/ingest", "#{dir}/ingest_evil"])
        FileUtils.touch("#{dir}/ingest_evil/secret")

        expect { described_class.new(root: "#{dir}/ingest").resolve("#{dir}/ingest_evil/secret") }.to raise_error described_class::InvalidPath
      end
    end

    it "allow symlinks which point out of the ingest folder" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(["#{dir}/ingest", "#{dir}/bitcur-archives/project"])
        FileUtils.touch("#{dir}/bitcur-archives/project/file.tif")
        File.symlink("#{dir}/bitcur-archives", "#{dir}/ingest/link")
        ingest_root = Pathname.new("#{dir}/ingest")
        folder_path = described_class.new(root: ingest_root)

        expect(folder_path.resolve("link")).to eq ingest_root.join("link")
        expect(folder_path.resolve("link/project/file.tif")).to eq ingest_root.join("link", "project", "file.tif")
        expect(folder_path.resolve("disk://#{ingest_root}/link/project")).to eq ingest_root.join("link", "project")
      end
    end

    it "rejects using .. to move out of the ingest folder through a symlink" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(["#{dir}/ingest", "#{dir}/bitcur-archives"])
        File.symlink("#{dir}/bitcur-archives", "#{dir}/ingest/link")

        expect { described_class.new(root: "#{dir}/ingest").resolve("link/../..") }.to raise_error described_class::InvalidPath
      end
    end

    it "re-raises File.expand_path ArgumentErrors as InvalidPath errors" do
      expect { ingest_folder_path.resolve("~") }.to raise_error described_class::InvalidPath
    end

    it "rejects paths which don't exist" do
      expect { ingest_folder_path.resolve("not/a/path") }.to raise_error described_class::InvalidPath
      expect { ingest_folder_path.resolve("bad\0path") }.to raise_error described_class::InvalidPath
    end
  end

  describe "#storage_id" do
    it "returns a disk:// ID for the resolved path" do
      expect(ingest_folder_path.storage_id("examples/bulk_ingest")).to eq "disk://#{root.join('examples', 'bulk_ingest')}"
    end
  end
end
