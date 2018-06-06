# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestArchivalMediaBagJob do
  describe "lae bag" do
    with_queue_adapter :inline
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
    let(:user) { FactoryBot.create(:admin) }

    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:query_service) { adapter.query_service }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
    let(:collection_cid) { collection.source_metadata_identifier.first }
    # We need to actually save it with persister to get the imported metadata
    let(:collection) do
      cs = DynamicChangeSet.new(ArchivalMediaCollection.new)
      cs.validate(source_metadata_identifier: "C0652")
      change_set_persister.save(change_set: cs)
    end

    before do
      stub_pulfa(pulfa_id: "C0652")
      stub_pulfa(pulfa_id: "C0652_c0377")
    end

    context "when you're ingesting to a collection you've already created" do
      before do
        described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
      end

      it "creates one FileSet per barcode (with part, e.g., 32101047382401_1)" do
        expect(query_service.find_all_of_model(model: FileSet).map(&:title)).to include ["32101047382401_1"], ["32101047382401_2"]
        expect(query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a).to include ["audio/wav"]
      end

      it "creates one FileSet for the pbcore xml file" do
        expect(query_service.find_all_of_model(model: FileSet).map(&:title).to_a).to include ["32101047382401"]
        expect(query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a).to include ["application/xml; schema=pbcore"]
      end

      it "adds all 3 file types to the file set" do
        file_set = query_service.find_all_of_model(model: FileSet).find { |fs| fs.title.include? "32101047382401_1" }
        expect(file_set.file_metadata.count).to eq 3
        expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
          "http://pcdm.org/use#PreservationMasterFile", "http://pcdm.org/use#ServiceFile", "http://pcdm.org/use#IntermediateFile"
        )
      end

      it "puts barcode, part, and transfer notes metadata on the file_set model" do
        file_set = query_service.find_all_of_model(model: FileSet).find { |fs| fs.part&.include? "1" }
        expect(file_set.barcode).to contain_exactly "32101047382401"
        expect(file_set.part).to contain_exactly "1"
        expect(file_set.transfer_notes.first).to start_with "Side A"
      end

      it "creates one MediaResource per component id" do
        expect(query_service.find_all_of_model(model: MediaResource).size).to eq 1
      end

      it "for each component id-based MediaRsource, puts it on the collection" do
        expect(query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids).size).to eq 1
      end
    end

    context "when the collection doesn't exist yet" do
      let(:collection_cid) { "C0652" }
      before do
        described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
      end

      it "creates a collection for you" do
        expect(query_service.find_all_of_model(model: ArchivalMediaCollection).size).to eq 1
        collection = query_service.find_all_of_model(model: ArchivalMediaCollection).first
        expect(query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids).size).to eq 1
      end
    end

    context "when another type of resource references the component ID" do
      before do
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: collection_cid)
        described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
      end

      it "doesn't try to use that other resource as an archival media collection" do
        expect(query_service.find_all_of_model(model: ScannedResource).first.source_metadata_identifier.first).to eq collection_cid
        expect(query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids).size).to eq 1
      end
    end

    context "with a path to an invalid bag" do
      let(:bag_path) { Rails.root.join("spec", "fixtures", "bags", "invalid_bag") }
      let(:logger) { instance_double(Logger) }
      before do
        allow(logger).to receive(:error)
        allow(Logger).to receive(:new).and_return(logger)
      end

      it "raises an error" do
        expect { described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user) }.to raise_error(
          ArchivalMediaBagParser::InvalidBagError, "Bag at #{bag_path} is an invalid bag"
        )
      end
    end
  end
end
