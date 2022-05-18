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
    stub_findingaid(pulfa_id: "C0652")
    stub_findingaid(pulfa_id: "C0652_c0377")
  end

  context "general functionality" do
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
    before do
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "creates one FileSet per barcode (with part, e.g., 32101047382401_1)" do
      expect(query_service.find_all_of_model(model: FileSet).map(&:title)).to include ["32101047382401_1"], ["32101047382401_2"]
      expect(query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a).to include ["audio/x-wav"]
    end

    it "adds all 3 file types to the file set" do
      file_set = query_service.find_all_of_model(model: FileSet).select { |fs| fs.title.include? "32101047382401_1" }.sort_by(&:created_at).last
      expect(file_set.file_metadata.count).to eq 5
      expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
        "http://pcdm.org/use#PreservationMasterFile", # Master
        "http://pcdm.org/use#ServiceFile", # MP3
        "http://pcdm.org/use#IntermediateFile", # Intermediate
        "http://pcdm.org/use#ServiceFile", # HLS Derivative
        "http://pcdm.org/use#ServiceFilePartial" # HLS Partial
      )
    end

    it "puts barcode, part, and transfer notes metadata on the file_set model" do
      file_set = query_service.find_all_of_model(model: FileSet).find { |fs| fs.side&.include? "1" }
      expect(file_set.barcode).to contain_exactly "32101047382401"
      expect(file_set.side).to contain_exactly "1"
      expect(file_set.transfer_notes.first).to start_with "Side A"
    end

    it "creates one Recording for the barcode and one for the component ID" do
      expect(query_service.find_all_of_model(model: ScannedResource).size).to eq 2
    end

    it "adds desired metadata to the Recording" do
      recording = query_service.find_all_of_model(model: ScannedResource).first
      expect(recording.upload_set_id).to be_present
      expect(recording.rights_statement).to eq [RightsStatements.copyright_not_evaluated]
    end

    it "for each component id-based Recording puts it on the collection" do
      collection = query_service.find_all_of_model(model: Collection).first
      expect(query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids).size).to eq 1
    end
  end

  describe "visibility settings" do
    before do
      cs = ChangeSet.for(Collection.new(change_set: "archival_media_collection"))
      cs.validate(source_metadata_identifier: collection_cid, visibility: vis_auth, slug: "test-collection")
      change_set_persister.save(change_set: cs)
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    context "when collection is set to authenticated" do
      let(:vis_auth) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      let(:read_auth) { Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED }

      it "assigns correct visibility and read_groups access control to each resource and file_set" do
        expect(query_service.find_all_of_model(model: ScannedResource).map(&:visibility)).to contain_exactly [vis_auth], [vis_auth]

        file_sets = query_service.find_all_of_model(model: FileSet)
        expect(file_sets.map(&:read_groups).to_a).to eq [
          [read_auth], [read_auth], [read_auth], [read_auth]
        ]
      end
    end

    context "when collection is set to public" do
      let(:vis_auth) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      let(:read_auth) { Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC }

      it "assigns correct visibility and read_groups access control to each resource and file_set" do
        expect(query_service.find_all_of_model(model: ScannedResource).map(&:visibility)).to contain_exactly [vis_auth], [vis_auth]

        file_sets = query_service.find_all_of_model(model: FileSet)
        expect(file_sets.map(&:read_groups).to_a).to eq [
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

  context "when the bag contains a JPEG image file", run_real_characterization: true do
    let(:tika_output) { tika_jpeg_output }

    before do
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "creates one FileSet with the filename as the title and the correct MIME type" do
      expect(query_service.find_all_of_model(model: FileSet).map(&:title).to_a).to include ["32101047382401_AssetFront.jpg"]
      expect(query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a).to include ["image/jpeg"]
    end
  end

  context "when the bag does not contain an image file", run_real_characterization: true do
    let(:tika_output) { tika_jpeg_output }
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag3") }

    before do
      stub_findingaid(pulfa_id: "C0652_c0383")

      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "does not have an image FileSet" do
      file_set_mime_types = query_service.find_all_of_model(model: FileSet).map(&:mime_type).to_a

      expect(file_set_mime_types).not_to include ["image/jpeg"]
      expect(file_set_mime_types).to include ["application/xml; schema=pbcore"]
      expect(file_set_mime_types).to include ["audio/x-wav"]
    end
  end

  context "when the bag does has files with multiple part names" do
    let(:collection_cid) { "C0652" }
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag4") }

    before do
      stub_findingaid(pulfa_id: "C0652_c0383")
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "add FileSets for each part" do
      file_sets = query_service.find_all_of_model(model: FileSet)
      expect(file_sets.map(&:title)).to include ["32101047382492_1_p1"], ["32101047382492_1_p2"]
      expect(file_sets.map(&:mime_type).to_a).to include ["audio/x-wav"]

      file_set = file_sets.select { |fs| fs.title.include? "32101047382492_1_p1" }.sort_by(&:created_at).last
      expect(file_set.file_metadata.count).to eq 5
      expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
        "http://pcdm.org/use#PreservationMasterFile", # Master
        "http://pcdm.org/use#ServiceFile", # MP3
        "http://pcdm.org/use#IntermediateFile", # Intermediate
        "http://pcdm.org/use#ServiceFile", # HLS Derivative
        "http://pcdm.org/use#ServiceFilePartial" # HLS Partial
      )

      file_set = file_sets.select { |fs| fs.title.include? "32101047382492_1_p2" }.sort_by(&:created_at).last
      expect(file_set.file_metadata.count).to eq 5
      expect(file_set.file_metadata.map { |file| file.use.first.to_s }).to contain_exactly(
        "http://pcdm.org/use#PreservationMasterFile", # Master
        "http://pcdm.org/use#ServiceFile", # MP3
        "http://pcdm.org/use#IntermediateFile", # Intermediate
        "http://pcdm.org/use#ServiceFile", # HLS Derivative
        "http://pcdm.org/use#ServiceFilePartial" # HLS Partial
      )
    end
  end

  context "when you're ingesting to a collection you've already created" do
    before do
      # create the collection
      cs = ChangeSet.for(Collection.new(change_set: "archival_media_collection"))
      cs.validate(source_metadata_identifier: collection_cid, slug: "test-collection")
      change_set_persister.save(change_set: cs)
      # ingest to the same collection_cid
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "uses the existing collection" do
      expect(query_service.find_all_of_model(model: Collection).size).to eq 1
    end
  end

  context "when the collection doesn't exist yet" do
    before do
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "creates a collection for you" do
      expect(query_service.find_all_of_model(model: Collection).size).to eq 1
      collection = query_service.find_all_of_model(model: Collection).first
      expect(query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids).size).to eq 1
    end
  end

  context "when another type of resource references the component ID" do
    before do
      # create the collection
      cs = ChangeSet.for(Collection.new(change_set: "archival_media_collection"))
      cs.validate(source_metadata_identifier: collection_cid, slug: "test-collection")
      change_set_persister.save(change_set: cs)
      # create another resource with the same component id
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: collection_cid)
      # ingest to the collection id
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
    end

    it "doesn't try to use that other resource as an archival media collection" do
      collection = query_service.find_all_of_model(model: Collection).first

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

  context "ingesting a bag, then another bag" do
    let(:bag_path1) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
    let(:bag_path2) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag2") }

    before do
      stub_findingaid(pulfa_id: "C0652_c0383")
      stub_findingaid(pulfa_id: "C0652_c0389")
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path1, user: user)
      described_class.perform_now(collection_component: collection_cid, bag_path: bag_path2, user: user)
    end

    it "uploads all resources to the same collection, giving them different upload set ids" do
      collection = query_service.find_all_of_model(model: Collection).first
      resources = query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids)
      expect(resources.size).to eq 2
      expect(resources.map(&:upload_set_id).to_a.uniq.size).to eq 2
    end
  end

  describe "ingesting a bag and applying EAD modeling" do
    context "a single cassette with 2 sides" do
      it "Creates 2 audio FileSets, 1 image FileSet, 1 xml FileSet, and 2 Resources", run_real_characterization: true do
        described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)

        collection = query_service.find_all_of_model(model: Collection).first
        resources = query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids)

        expect(resources.size).to eq 1
        expect(resources.first.source_metadata_identifier).to eq ["C0652_c0377"]

        member = Wayfinder.for(resources.first).members.first
        expect(member).to be_a ScannedResource
        expect(member.change_set).to eq "recording"
        expect(member.local_identifier.first).to eq "32101047382401"
        expect(member.title).to eq ["Interview: ERM / Jose Donoso (A2)"]

        file_sets = Wayfinder.for(member).members
        expect(file_sets.count).to eq 4
        expect(file_sets.flat_map(&:title)).to contain_exactly(
          "32101047382401.xml",
          "32101047382401_1",
          "32101047382401_2",
          "32101047382401_AssetFront.jpg"
        )
        side_1_idx = file_sets.index { |x| x.title.first.include?("_1") }
        side_2_idx = file_sets.index { |x| x.title.first.include?("_2") }
        expect(side_1_idx < side_2_idx).to eq true
      end
    end
    context "a barcode not in the EAD", run_real_characterization: true do
      let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag_unknown_barcode") }
      it "creates a Recording which is put in a filler descriptive proxy" do
        stub_findingaid(pulfa_id: "C0652_c0383")
        stub_findingaid(pulfa_id: "C0652_c0389")
        described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)

        collection = query_service.find_all_of_model(model: Collection).first
        resources = query_service.find_inverse_references_by(resource: collection, property: :member_of_collection_ids)

        expect(resources.size).to eq 1
        expect(resources.first.title.first).to eq "[Unorganized Barcodes]"
        expect(resources.first.local_identifier.first).to eq "unorganized"
        expect(resources.first.rights_statement.first).to eq RightsStatements.copyright_not_evaluated

        members = Wayfinder.for(resources.first).members
        expect(members.length).to eq 1
        expect(members.first.local_identifier).to eq ["32101047382400"]
      end
    end
    context "3 cassettes in two components" do
      let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_demo_bag") }

      before do
        stub_findingaid(pulfa_id: "C0652_c0383")
        stub_findingaid(pulfa_id: "C0652_c0389")
      end

      it "Creates 3 Resources from barcodes, 2 Resources from component IDs", run_real_characterization: true do
        described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)

        # Ensure there are two descriptive resources.
        collection = query_service.find_all_of_model(model: Collection).first
        resources = Wayfinder.for(collection).members
        expect(resources.size).to eq 2
        expect(resources.flat_map(&:source_metadata_identifier)).to contain_exactly(
          "C0652_c0383",
          "C0652_c0389"
        )
        expect(resources.map(&:change_set).uniq).to contain_exactly "recording"

        # c0383 has two barcodes associated with it in the EAD.
        resource383 = resources.find { |x| x.source_metadata_identifier == ["C0652_c0383"] }
        members383 = Wayfinder.for(resource383).members
        expect(members383.count).to eq 2
        expect(members383.map(&:class).uniq).to contain_exactly ScannedResource
        expect(members383.map(&:change_set).uniq).to contain_exactly "recording"
        expect(members383.map(&:local_identifier)).to contain_exactly(
          ["32101047382484"], ["32101047382492"]
        )
        # Usually you want tape 1 first, but we artificially arranged it this
        # way to ensure we're testing order properly (given the barcode sort
        # order of this set of files)
        expect(members383.map(&:title)).to eq(
          [
            ["Interview: Fitas / ERM, Tape 2 (A8)"], ["Interview: Fitas / ERM, Tape 1 (A8)"]
          ]
        )

        # Member resources have the appropriate FileSets for their barcode.
        tape1 = members383.find { |x| x.local_identifier.include?("32101047382484") }
        tape1_file_sets = Wayfinder.for(tape1).members
        expect(tape1_file_sets.flat_map(&:title)).to contain_exactly(
          "32101047382484.xml",
          "32101047382484_1",
          "32101047382484_2",
          "32101047382484_AssetFront.jpg"
        )
        tape2 = members383.find { |x| x.local_identifier.include?("32101047382492") }
        tape2_file_sets = Wayfinder.for(tape2).members
        expect(tape2_file_sets.flat_map(&:title)).to contain_exactly(
          "32101047382492.xml",
          "32101047382492_1",
          "32101047382492_AssetFront.jpg"
        )

        # c0389 has one barcode associated with it in the EAD.
        resource389 = resources.find { |x| x.source_metadata_identifier == ["C0652_c0389"] }
        members389 = Wayfinder.for(resource389).members
        expect(members389.count).to eq 1
        expect(members389.map(&:class).uniq).to contain_exactly ScannedResource
        expect(members389.map(&:local_identifier)).to contain_exactly(
          ["32101047382617"]
        )
        expect(members389.map(&:title)).to eq(
          [
            ["Readings: Pablo Neruda III (C3)"]
          ]
        )

        # Member resources have the appropriate FileSets for their barcode.
        tape1 = members389.first
        expect(tape1.downloadable).to eq ["public"]
        tape1_file_sets = Wayfinder.for(tape1).members
        expect(tape1_file_sets.flat_map(&:title)).to contain_exactly(
          "32101047382617.xml",
          "32101047382617_1",
          "32101047382617_2",
          "32101047382617_AssetFront.jpg"
        )

        tape1_side1 = tape1_file_sets.find { |x| x.title.first.include?("_1") }
        expect(tape1_side1.derivative_partial_files).not_to be_blank
        expect(tape1_side1.preservation_file.duration).not_to be_blank
      end

      it "gives all Recordings the same upload set id" do
        described_class.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)

        expect(query_service.find_all_of_model(model: ScannedResource).map(&:upload_set_id).to_a.uniq.size).to eq 1
      end
    end
  end
end
