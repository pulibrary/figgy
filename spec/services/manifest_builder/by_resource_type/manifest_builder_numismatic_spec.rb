# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  context "when given a numismatic issue" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: numismatic_issue.id)) }
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:numismatic_issue) { FactoryBot.create_for_repository(:numismatic_issue) }
    let(:change_set) { Numismatics::IssueChangeSet.new(numismatic_issue, member_ids: [coin1.id, coin2.id, coin3.id]) }
    let(:coin1) { FactoryBot.create_for_repository(:coin, files: [file1]) }
    let(:coin2) { FactoryBot.create_for_repository(:coin, files: [file2]) }
    let(:coin3) { FactoryBot.create_for_repository(:coin) }
    let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    let(:file2) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    before do
      numismatic_issue
      change_set_persister.save(change_set: change_set)
    end
    it "builds a IIIF document with only the coins that have images" do
      output = manifest_builder.build
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["manifests"].length).to eq 2
      expect(output["manifests"][0]["label"]).to eq ["Coin: 1"]
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/numismatics/coins/#{coin1.id}/manifest"
      expect(output["manifests"][1]["label"]).to eq ["Coin: 2"]
    end
  end
end
