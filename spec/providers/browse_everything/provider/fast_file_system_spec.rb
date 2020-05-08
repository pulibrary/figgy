# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrowseEverything::Provider::FastFileSystem do
  describe "#name" do
    it "is File System" do
      expect(described_class.new.name).to eq "File System"
    end
  end
  describe ".find_container" do
    it "returns a container with bytestreams in alphabetical order" do
      provider = described_class.new
      allow(Dir).to receive(:children).and_return(
        [
          "000002.tif",
          "000001.tif"
        ]
      )
      container = provider.find_container(id: Rails.root.join("spec", "fixtures", "order_test").to_s)

      expect(container.bytestreams.first.name).to eq "000001.tif"
    end
    it "returns a container with no hidden files as bytestreams" do
      provider = described_class.new
      container = provider.find_container(id: Rails.root.join("spec", "fixtures", "hidden_files", "32101075851400").to_s)

      expect(container.bytestreams.length).to eq 1
    end
  end
end
