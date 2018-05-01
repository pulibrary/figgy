# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IngestArchivalMediaBagJob do
  describe 'lae bag' do
    with_queue_adapter :inline
    let(:bag_path) { Rails.root.join('spec', 'fixtures', 'av', 'la_c0652_2017_05_bag') }
    let(:xml) { File.open(Rails.root.join('spec', 'fixtures', 'av', 'C0652.xml'), 'r') }
    let(:user) { FactoryBot.create(:admin) }

    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:query_service) { adapter.query_service }
    let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
    let(:collection_cid) { collection.source_metadata_identifier }
    # We need to actually save it with persister to get the imported metadata
    let(:collection) do
      cs = DynamicChangeSet.new(ArchivalMediaCollection.new)
      cs.validate(source_metadata_identifier: "C0652", bag_path: bag_path)
      cs.sync
      change_set_persister.save(change_set: cs)
    end

    before do
      stub_request(:get, "https://findingaids.princeton.edu/collections/C0652.xml?scope=record")
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Faraday v0.9.2' })
        .to_return(status: 200, body: xml, headers: {})
      described_class.perform_now(collection_component: collection_cid.first, bag_path: bag_path, user: user)
    end

    it 'creates one FileSet per barcode (with part, e.g., 32101047382401_1)' do
      expect(query_service.find_all_of_model(model: FileSet).size).to eq 2
    end

    it 'adds all 3 file types to the file set' do
      file_set = query_service.find_all_of_model(model: FileSet).first
      expect(file_set.file_metadata.count).to eq 3
      expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
        "http://pcdm.org/use#PreservationMasterFile", "http://pcdm.org/use#ServiceFile", "http://pcdm.org/use#IntermediateFile"
      )
    end

    it 'creates one MediaResource per component id' do
      expect(query_service.find_all_of_model(model: MediaResource).size).to eq 1
    end

    it 'for each compopnent id-based MediaRsource, puts it on the collection' do
      expect(query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids).size).to eq 1
    end
  end
end
