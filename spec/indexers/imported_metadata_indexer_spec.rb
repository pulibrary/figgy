# frozen_string_literal: true
require "rails_helper"

RSpec.describe ImportedMetadataIndexer do
  describe ".to_solr" do
    let(:source_id) { "10001789" }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:change_set_persister) do
      ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
    end

    before do
      stub_catalog(bib_id: source_id)
    end
    it "applies remote metadata from catalog to an imported metadata resource" do
      resource = FactoryBot.build(:scanned_map, title: [])
      change_set = ScannedMapChangeSet.new(resource)
      change_set.validate(source_metadata_identifier: "10001789")
      resource = change_set_persister.save(change_set: change_set)
      output = described_class.new(resource: resource).to_solr

      expect(output[:call_number_tsim]).to eq ["G8731.F7 1949 .C6 (b)"]
      expect(output["imported_cartographer_tesim"]).to eq ["Nigeria. Survey Department"]
    end

    it "indexes objects as plain strings" do
      resource = FactoryBot.build(:scanned_resource)
      resource.imported_metadata = [ImportedMetadata.new(creator: RDF::Literal.new("Test Literal"))]
      output = described_class.new(resource: resource).to_solr
      expect(output["imported_creator_tesim"]).to eq ["Test Literal"]
    end

    it "indexes string imported metadata" do
      resource = FactoryBot.build(:scanned_resource)
      resource.imported_metadata = [ImportedMetadata.new(layer_name: "layer")]
      output = described_class.new(resource: resource).to_solr
      expect(output["imported_layer_name_tesim"]).to eq "layer"
    end
  end
end
