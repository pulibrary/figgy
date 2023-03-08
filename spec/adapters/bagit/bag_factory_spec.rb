# frozen_string_literal: true
require "rails_helper"

RSpec.describe Bagit::BagFactory, run_real_derivatives: true do
  subject(:bag_factory) { described_class.new(adapter: adapter) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:adapter) do
    Bagit::MetadataAdapter.new(
      base_path: bag_path
    )
  end
  let(:bag_path) { Rails.root.join("tmp", "test_bags") }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file], source_metadata_identifier: "991234563506421", identifier: "ark:/88435/7d278t10z") }
  before do
    stub_catalog(bib_id: "991234563506421")
  end
  after do
    FileUtils.rm_rf(bag_path) if File.exist?(bag_path)
  end

  describe ".new" do
    it "returns a bag factory for a resource" do
      output = bag_factory.new(resource: resource)
      expect(output).to be_a Bagit::BagFactory::ResourceFactory
    end
  end

  describe ".create" do
    let(:resource_factory) { bag_factory.new(resource: resource) }
    it "builds a bag on disk" do
      resource_factory.create!
      resource_path = bag_path.join(resource.id.to_s)
      expect(File.exist?(resource_path)).to eq true
      expect(File.read(resource_path.join("bagit.txt")).split("\n")).to eq [
        "BagIt-Version: 0.97",
        "Tag-File-Character-Encoding: UTF-8"
      ]
      expect(File.exist?(resource_path.join("metadata", "#{resource.id}.jsonld"))).to eq true
      expect(File.exist?(resource_path.join("tagmanifest-sha256.txt"))).to eq true
      tag_manifest_contents = File.read(resource_path.join("tagmanifest-sha256.txt")).split("\n")
      expect(tag_manifest_contents).to eq [
        "#{Digest::SHA256.file(resource_path.join('metadata', "#{resource.id}.jsonld")).hexdigest}  metadata/#{resource.id}.jsonld"
      ]
      # bag-info.txt
      expect(File.exist?(resource_path.join("bag-info.txt"))).to eq true
      date = Time.current.strftime("%Y-%m-%d")
      expect(File.read(resource_path.join("bag-info.txt")).split("\n")).to eq [
        "Bagging-Date: #{date}",
        "External-Description: #{resource.title.first}",
        "External-Identifier: ark:/88435/7d278t10z",
        "Internal-Sender-Identifier: http://www.example.com/catalog/#{resource.id}",
        "Organization-Address: One Washington Road, Princeton, NJ 08544-2098, USA",
        "Source-Organization: Princeton University Library"
      ]
    end
  end
end
