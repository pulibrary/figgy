# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestArchivalMediaBagJob do
  with_queue_adapter :inline
  let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
  let(:user) { FactoryBot.create(:admin) }

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:collection_cid) { "C0652" }

  before do
    stub_pulfa(pulfa_id: "C0652")
    stub_pulfa(pulfa_id: "C0652_c0377")
  end

  context "general functionality" do
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
    before do
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "creates one FileSet per barcode (with part, e.g., 32101047382401_1)" do
      expect(query_service.find_all_of_model(model: FileSet).map(&:title)).to include ["32101047382401_1"], ["32101047382401_2"]
      expect(query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a).to include ["audio/wav"]
    end

    it "adds all 3 file types to the file set" do
      file_set = query_service.find_all_of_model(model: FileSet).find { |fs| fs.title.include? "32101047382401_1" }
      expect(file_set.file_metadata.count).to eq 3
      expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
        "http://pcdm.org/use#PreservationMasterFile", "http://pcdm.org/use#ServiceFile", "http://pcdm.org/use#IntermediateFile"
      )
    end

    it "puts barcode, part, and transfer notes metadata on the file_set model" do
      file_set = query_service.find_all_of_model(model: FileSet).find { |fs| fs.side&.include? "1" }
      expect(file_set.barcode).to contain_exactly "32101047382401"
      expect(file_set.side).to contain_exactly "1"
      expect(file_set.transfer_notes.first).to start_with "Side A"
    end

    it "creates one MediaResource per component id" do
      expect(query_service.find_all_of_model(model: MediaResource).size).to eq 1
    end

    it "adds an upload set id to the MediaResource" do
      expect(query_service.find_all_of_model(model: MediaResource).first.upload_set_id).to be_present
    end

    it "for each component id-based MediaRsource, puts it on the collection" do
      collection = query_service.find_all_of_model(model: ArchivalMediaCollection).first
      expect(query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids).size).to eq 1
    end
  end

  describe "visibility settings" do
    before do
      cs = DynamicChangeSet.new(ArchivalMediaCollection.new)
      cs.validate(source_metadata_identifier: collection_cid, visibility: vis_auth)
      change_set_persister.save(change_set: cs)
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    context "when collection is set to authenticated" do
      let(:vis_auth) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      let(:read_auth) { Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED }

      it "assigns correct visibility and read_groups access control to each resource and file_set" do
        expect(query_service.find_all_of_model(model: MediaResource).map(&:visibility)).to contain_exactly [vis_auth]

        file_sets = query_service.find_all_of_model(model: FileSet)
        expect(file_sets.map(&:read_groups).to_a).to eq [
          [read_auth], [read_auth], [read_auth], [read_auth],
          [read_auth], [read_auth], [read_auth], [read_auth]
        ]
      end
    end

    context "when collection is set to public" do
      let(:vis_auth) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      let(:read_auth) { Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC }

      it "assigns correct visibility and read_groups access control to each resource and file_set" do
        expect(query_service.find_all_of_model(model: MediaResource).map(&:visibility)).to contain_exactly [vis_auth]

        file_sets = query_service.find_all_of_model(model: FileSet)
        expect(file_sets.map(&:read_groups).to_a).to eq [
          [read_auth], [read_auth], [read_auth], [read_auth],
          [read_auth], [read_auth], [read_auth], [read_auth]
        ]
      end
    end
  end

  context "when the bag contains a PBCore XML file" do
    let(:tika_output) { tika_xml_pbcore_output }

    before do
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "creates one FileSet with the filename as the title and the correct MIME type" do
      expect(query_service.find_all_of_model(model: FileSet).map(&:title).to_a).to include ["32101047382401.xml"]
      expect(query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a).to include ["application/xml; schema=pbcore"]
    end
  end

  context "when the bag contains a JPEG image file" do
    let(:tika_output) { tika_jpeg_output }

    before do
      ruby_tika = instance_double(RubyTikaApp)
      allow(ruby_tika).to receive(:to_json).and_return(tika_xml_pbcore_output, tika_jpeg_output)
      allow(RubyTikaApp).to receive(:new).and_return(ruby_tika)

      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "creates one FileSet with the filename as the title and the correct MIME type" do
      expect(query_service.find_all_of_model(model: FileSet).map(&:title).to_a).to include ["32101047382401_AssetFront.jpg"]
      expect(query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a).to include ["image/jpeg"]
    end
  end

  context "when the bag does not contain an image file" do
    let(:tika_output) { tika_jpeg_output }
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag3") }

    before do
      ruby_tika = instance_double(RubyTikaApp)
      allow(ruby_tika).to receive(:to_json).and_return(tika_xml_pbcore_output, tika_jpeg_output)
      allow(RubyTikaApp).to receive(:new).and_return(ruby_tika)

      stub_pulfa(pulfa_id: "C0652_c0383")

      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "does not have an image FileSet" do
      file_set_mime_types = query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a

      expect(file_set_mime_types).not_to include ["image/jpeg"]
      expect(file_set_mime_types).to include ["application/xml; schema=pbcore"]
      expect(file_set_mime_types).to include ["audio/wav"]
    end
  end

  context "when the bag does has files with multiple part names" do
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag4") }
    let(:file_sets) do
      results = query_service.find_all_of_model(model: FileSet)
      results.to_a
    end

    before do
      stub_pulfa(pulfa_id: "C0652_c0383")
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "add FileSets for each part" do
      expect(file_sets.map(&:title)).to include ["32101047382492_1_p1"], ["32101047382492_1_p2"]
      expect(file_sets.map(&:mime_type).to_a).to include ["audio/wav"]

      file_set = file_sets.find { |fs| fs.title.include? "32101047382492_1_p1" }
      expect(file_set.file_metadata.count).to eq 3
      expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
        "http://pcdm.org/use#PreservationMasterFile", "http://pcdm.org/use#ServiceFile", "http://pcdm.org/use#IntermediateFile"
      )

      file_set = file_sets.find { |fs| fs.title.include? "32101047382492_1_p2" }
      expect(file_set.file_metadata.count).to eq 3
      expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
        "http://pcdm.org/use#PreservationMasterFile", "http://pcdm.org/use#ServiceFile", "http://pcdm.org/use#IntermediateFile"
      )
    end
  end

  context "when you're ingesting to a collection you've already created" do
    before do
      # create the collection
      cs = DynamicChangeSet.new(ArchivalMediaCollection.new)
      cs.validate(source_metadata_identifier: collection_cid)
      change_set_persister.save(change_set: cs)
      # ingest to the same collection_cid
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "uses the existing collection" do
      expect(query_service.find_all_of_model(model: ArchivalMediaCollection).size).to eq 1
    end
  end

  context "when the collection doesn't exist yet" do
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
      # create the collection
      cs = DynamicChangeSet.new(ArchivalMediaCollection.new)
      cs.validate(source_metadata_identifier: collection_cid)
      change_set_persister.save(change_set: cs)
      # create another resource with the same component id
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: collection_cid)
      # ingest to the collection id
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "doesn't try to use that other resource as an archival media collection" do
      collection = query_service.find_all_of_model(model: ArchivalMediaCollection).first
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
        IngestArchivalMediaBagJob::InvalidBagError, "Bag at #{bag_path} is an invalid bag"
      )
    end
  end

  context "ingesting a more complicated bag" do
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_demo_bag") }

    before do
      stub_pulfa(pulfa_id: "C0652_c0383")
      stub_pulfa(pulfa_id: "C0652_c0389")
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "collects multiple barcodes with the same component id onto a single MediaResource" do
      expect(query_service.find_all_of_model(model: MediaResource).size).to eq 2
      expect(query_service.find_all_of_model(model: MediaResource).map(&:title)).to contain_exactly(
        ["Readings: Pablo Neruda III (C3)"],
        ["Interview: Fitas / ERM, Tape 1-2 (A8)"]
      )
    end

    it "gives all MediaResources the same upload set id" do
      expect(query_service.find_all_of_model(model: MediaResource).map(&:upload_set_id).to_a.uniq.size).to eq 1
    end
  end

  context "ingesting a bag, then another bag" do
    let(:bag_path1) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
    let(:bag_path2) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag2") }

    before do
      stub_pulfa(pulfa_id: "C0652_c0383")
      stub_pulfa(pulfa_id: "C0652_c0389")
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path1, user: user)
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path2, user: user)
    end

    it "uploads all resources to the same collection, giving them different upload set ids" do
      collection = query_service.find_all_of_model(model: ArchivalMediaCollection).first
      resources = query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids)
      expect(resources.size).to eq 2
      expect(resources.map(&:upload_set_id).to_a.uniq.size).to eq 2
    end
  end
end
