# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkIngestService do
  subject(:ingester) { described_class.new(change_set_persister: change_set_persister, logger: logger) }
  let(:logger) { Logger.new(nil) }
  let(:query_service) { metadata_adapter.query_service }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) do
    ChangeSetPersister.new(
      metadata_adapter: metadata_adapter,
      storage_adapter: storage_adapter
    )
  end

  describe "#attach_each_dir" do
    context "with a set of LAE images" do
      let(:barcode1) { "32101075851400" }
      let(:barcode2) { "32101075851418" }
      let(:lae_dir) { Rails.root.join("spec", "fixtures", "lae") }
      let(:folder1) { FactoryBot.create_for_repository(:ephemera_folder, barcode: [barcode1]) }
      let(:folder2) { FactoryBot.create_for_repository(:ephemera_folder, barcode: [barcode2]) }
      before do
        folder1
        folder2
        stub_request(:get, "https://bibdata.princeton.edu/bibliographic/32101075851400/jsonld").and_return(status: 404)
        stub_request(:get, "https://bibdata.princeton.edu/bibliographic/32101075851418/jsonld").and_return(status: 404)
      end

      it "attaches the files" do
        ingester.attach_each_dir(base_directory: lae_dir, property: :barcode, file_filters: [".tif"])

        reloaded1 = query_service.find_by(id: folder1.id)
        reloaded2 = query_service.find_by(id: folder2.id)

        expect(reloaded1.member_ids.length).to eq 1
        expect(reloaded2.member_ids.length).to eq 2
      end
    end

    context "with a path to a non-existent directory" do
      it "raises an error" do
        expect { ingester.attach_each_dir(base_directory: "no/exist") }.to raise_error(ArgumentError, "BulkIngestService: Directory does not exist: no/exist")
      end
    end

    context "with a path to an empty directory" do
      let(:empty_dir) { Rails.root.join("spec", "fixtures", "empty") }
      before do
        Dir.mkdir(empty_dir)
      end
      after do
        Dir.rmdir(empty_dir)
      end
      it "raises an error" do
        expect { ingester.attach_each_dir(base_directory: empty_dir) }.to raise_error(ArgumentError, "BulkIngestService: Directory is empty: #{empty_dir}")
      end
    end

    context "with a path to a directory containing hidden files" do
      let(:dir) { Rails.root.join("spec", "fixtures", "hidden_files") }
      let(:barcode1) { "32101075851400" }
      let(:folder1) { FactoryBot.create_for_repository(:ephemera_folder, barcode: [barcode1]) }

      before do
        folder1
        stub_request(:get, "https://bibdata.princeton.edu/bibliographic/32101075851400/jsonld").and_return(status: 404)
      end

      it "does not attach any hidden files" do
        ingester.attach_each_dir(base_directory: dir, property: :barcode)

        reloaded1 = query_service.find_by(id: folder1.id)

        expect(reloaded1.member_ids.length).to eq 1
        file_set = reloaded1.decorate.members.first
        expect(file_set.file_metadata.length).to eq 1
        expect(file_set.file_metadata.first.label).to eq ["normal_file.txt"]
      end
    end
  end

  describe "#attach_dir" do
    let(:logger) { Logger.new(nil) }
    let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
    let(:bib) { "9946093213506421" }
    let(:local_id) { "cico:xyz" }
    let(:replaces) { "pudl0001/9946093213506421/331" }
    let(:coll) { FactoryBot.create_for_repository(:collection) }
    before do
      stub_catalog(bib_id: "9946093213506421")
      stub_ezid
    end
    context "with a directory of Scanned TIFFs" do
      it "ingests the resources, skipping dotfiles and ignored files" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".tif"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        updated_collection = query_service.find_by(id: coll.id)
        decorated_collection = updated_collection.decorate
        expect(decorated_collection.members.to_a.length).to eq 1
        expect(decorated_collection.members.first.member_ids.length).to eq 2

        resource = decorated_collection.members.to_a.first
        expect(resource.source_metadata_identifier).to include(bib)
        expect(resource.local_identifier).to include(local_id)
      end
      it "maintains file names if preserve_file_names is true" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".tif"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id],
          preserve_file_names: true
        )

        updated_collection = query_service.find_by(id: coll.id)

        resource = Wayfinder.for(updated_collection).members.first
        members = Wayfinder.for(resource).members
        expect(members.first.title).to eq ["color"]
      end
    end

    context "when using the SimpleChangeSet" do
      subject(:ingester) { described_class.new(change_set_persister: change_set_persister, logger: logger, change_set_param: "simple") }

      before do
        # Used for checking whether or not the PULFA record exists
        stub_request(:get, "https://findingaids.princeton.edu/collections/ingest/single.xml?scope=record")
        stub_request(:get, "https://findingaids.princeton.edu/collections/ingest/single.xml")
      end

      it "ingests the resources as SimpleResource objects" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".tif"],
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        updated_collection = query_service.find_by(id: coll.id)
        decorated_collection = updated_collection.decorate
        expect(decorated_collection.members.to_a.length).to eq 1
        expect(decorated_collection.members.first.member_ids.length).to eq 2

        resource = decorated_collection.members.to_a.first
        expect(resource).to be_a ScannedResource
        expect(resource.local_identifier).to include(local_id)
        expect(resource.change_set).to eq "simple"
      end
    end

    context "with a relative path for the directory" do
      let(:bulk_ingester) { described_class.new(change_set_persister: change_set_persister, logger: logger) }
      let(:single_dir) { File.join("spec", "fixtures", "ingest_single") }
      before do
        allow(bulk_ingester).to receive(:attach_children)
      end
      it "attaches directories using an absolute path" do
        bulk_ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".tif"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        expect(bulk_ingester).to have_received(:attach_children).with(
          hash_including(path: Rails.root.join("spec", "fixtures", "ingest_single"))
        )
      end
    end

    context "with a directory of subdirectories of TIFFs" do
      let(:logger) { Logger.new(nil) }
      let(:multi_dir) { Rails.root.join("spec", "fixtures", "ingest_multi") }
      let(:bib) { "9946093213506421" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/9946093213506421/331" }
      let(:coll) { FactoryBot.create(:collection) }

      before do
        stub_catalog(bib_id: "9946093213506421")
        stub_ezid
      end

      it "ingests them as child resources, imports figgy_metadata.json, and does not add them to collections", bulk: true do
        coll = FactoryBot.create_for_repository(:collection)

        ingester.attach_dir(
          base_directory: multi_dir,
          file_filters: [".tif"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        updated_collection = query_service.find_by(id: coll.id)
        decorated_collection = updated_collection.decorate
        expect(decorated_collection.members.to_a.length).to eq 1

        resource = decorated_collection.members.to_a.first
        expect(resource).to be_a ScannedResource
        expect(resource.source_metadata_identifier).to include(bib)
        expect(resource.local_identifier).to include(local_id)
        expect(resource.member_of_collection_ids). to eq [coll.id]

        decorated_resource = resource.decorate
        expect(decorated_resource.volumes.length).to eq 2
        child_resource = decorated_resource.volumes.first
        expect(child_resource).to be_a ScannedResource
        expect(child_resource.local_identifier).to include(local_id)
        expect(child_resource.source_metadata_identifier).to be_nil
        expect(child_resource.title).to eq ["vol1"]
        expect(child_resource.member_of_collection_ids). to be_nil
        # This is in figgy_metadata.json for Vol1.
        expect(child_resource.series).to eq ["Cool stuff"]
      end
    end

    context "when subdirectories have a figgy_metadata.json" do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single_figgy_metadata") }
      let(:bib) { "9946093213506421" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/9946093213506421/331" }
      let(:coll) { FactoryBot.create_for_repository(:collection) }
      before do
        stub_catalog(bib_id: "9946093213506421")
        stub_ezid
      end

      it "applies that metadata, but still imports metadata" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".tif"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id],
          depositor: "tpend"
        )

        updated_collection = query_service.find_by(id: coll.id)
        decorated_collection = updated_collection.decorate
        expect(decorated_collection.members.to_a.length).to eq 1
        expect(decorated_collection.members.first.member_ids.length).to eq 2

        resource = decorated_collection.members.to_a.first
        expect(resource.source_metadata_identifier).to include(bib)
        expect(resource.local_identifier).to include(local_id)
        expect(resource.viewing_hint).to eq ["paged"] # brought in from figgy_metadata.json
        expect(resource.member_ids.length).to eq 2 # color.tif, gray.tif
        expect(resource.depositor).to eq ["tpend"]
        expect(resource.title.first.to_s).to eq "Bible, Latin." # Imported from source_metadata_identifier.
        expect(resource.title).not_to include "My Title" # figgy_metadata.json has this defined, it gets overridden by the above imported title.

        first_member = Wayfinder.for(resource).members.first
        expect(first_member.title).to eq ["1"]
      end

      it "applies metadata if it doesn't import metadata" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".tif"],
          local_identifier: local_id,
          member_of_collection_ids: [coll.id],
          depositor: "tpend"
        )

        updated_collection = query_service.find_by(id: coll.id)
        decorated_collection = updated_collection.decorate
        expect(decorated_collection.members.to_a.length).to eq 1
        expect(decorated_collection.members.first.member_ids.length).to eq 2

        resource = decorated_collection.members.to_a.first
        expect(resource.local_identifier).to include(local_id)
        expect(resource.viewing_hint).to eq ["paged"] # brought in from figgy_metadata.json
        expect(resource.member_ids.length).to eq 2 # color.tif, gray.tif
        expect(resource.depositor).to eq ["tpend"]
        expect(resource.title).to eq ["My Title"] # brought in from figgy_metadata.json

        first_member = Wayfinder.for(resource).members.first
        expect(first_member.title).to eq ["1"]
      end
      context "when the figgy_metadata.json file has a source_metadata_identifier" do
        let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single_figgy_metadata_with_id") }
        it "uses it to import metadata" do
          ingester.attach_dir(
            base_directory: single_dir,
            file_filters: [".tif"],
            local_identifier: local_id,
            member_of_collection_ids: [coll.id],
            depositor: "tpend"
          )

          updated_collection = query_service.find_by(id: coll.id)
          decorated_collection = updated_collection.decorate

          resource = decorated_collection.members.to_a.first
          expect(resource.title.first.to_s).to eq "Bible, Latin." # Imported from figgy_metadata source metadata identifier.

          first_member = Wayfinder.for(resource).members.first
          expect(first_member.title).to eq ["1"]
        end
      end
    end

    context "when ingesting AV bags" do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "av", "bulk_ingest", "c0652_2017_05_bag") }
      let(:bib) { nil }
      let(:coll) { FactoryBot.create_for_repository(:collection) }
      before do
        stub_catalog(bib_id: "9946093213506421")
        stub_ezid(shoulder: "99999/fk4", blade: "994603213506421")
        stub_findingaid(pulfa_id: "C0652")
        stub_findingaid(pulfa_id: "C0652_c0377")
      end
      with_queue_adapter :inline
      it "ingests the bag as an archival media bag" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".tif"],
          source_metadata_identifier: bib,
          member_of_collection_ids: [coll.id.to_s],
          visibility: "open",
          depositor: "tpend"
        )
        resources = Wayfinder.for(coll).members
        expect(resources.length).to eq 1
        expect(query_service.find_all_of_model(model: ScannedResource).size).to eq 2
        file_set = query_service.find_all_of_model(model: FileSet).find { |fs| fs.side&.include? "1" }
        expect(file_set.barcode).to contain_exactly "32101047382401"
        expect(file_set.side).to contain_exactly "1"
        expect(file_set.transfer_notes.first).to start_with "Side A"
        expect(resources.first.read_groups).to eq ["public"]
      end
    end

    context "when ingesting video and vtt caption file" do
      let(:single_dir) { Rails.root.join("spec", "fixtures", "av", "bulk_ingest", "video_with_captions") }
      with_queue_adapter :inline
      let(:coll) { FactoryBot.create_for_repository(:collection) }
      it "ingests them as file_metadatas on the same FileSet" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".mp4"],
          title: "Interview",
          member_of_collection_ids: [coll.id.to_s],
          visibility: "open",
          depositor: "tpend"
        )
        resources = Wayfinder.for(coll).members
        expect(resources.length).to eq 1
        expect(query_service.find_all_of_model(model: ScannedResource).size).to eq 1
        expect(query_service.find_all_of_model(model: FileSet).size).to eq 1
        file_set = query_service.find_all_of_model(model: FileSet).first
        expect(file_set.file_metadata.size).to eq 4
        expect(file_set.file_metadata.flat_map(&:use)).to contain_exactly(
          ::PcdmUse::OriginalFile,
          ::PcdmUse::ServiceFile,
          ::PcdmUse::ServiceFilePartial,
          ::PcdmUse::Caption
        )
        vtt_file_metadata = file_set.captions.first
        expect(vtt_file_metadata.original_filename).to eq(["city--original-language--eng.vtt"])
        expect(vtt_file_metadata.caption_language).to eq(["eng"])
        expect(vtt_file_metadata.original_language_caption).to eq(true)
      end
    end

    context "when ingesting video and two caption files, where one has a nonexistent ISO 639 code" do
      let(:single_dir) { Rails.root.join("spec", "fixtures", "av", "bulk_ingest", "video_with_multiple_captions") }
      with_queue_adapter :inline
      let(:coll) { FactoryBot.create_for_repository(:collection) }
      it "ingests them as file_metadatas on the same FileSet, using ISO 639 code 'und' for undetermined" do
        ingester.attach_dir(
          base_directory: single_dir,
          file_filters: [".mp4"],
          title: "Interview",
          member_of_collection_ids: [coll.id.to_s],
          visibility: "open",
          depositor: "tpend"
        )
        resources = Wayfinder.for(coll).members
        expect(resources.length).to eq 1
        expect(query_service.find_all_of_model(model: ScannedResource).size).to eq 1
        expect(query_service.find_all_of_model(model: FileSet).size).to eq 1
        file_set = query_service.find_all_of_model(model: FileSet).first
        expect(file_set.file_metadata.size).to eq 5
        expect(file_set.file_metadata.flat_map(&:use)).to contain_exactly(
          ::PcdmUse::OriginalFile,
          ::PcdmUse::ServiceFile,
          ::PcdmUse::ServiceFilePartial,
          ::PcdmUse::Caption,
          ::PcdmUse::Caption
        )
        vtt_file_metadatas = file_set.captions
        original_vtt = vtt_file_metadatas.find { |fm| fm.original_filename == ["city--original-language--engg.vtt"] }
        spa_vtt = vtt_file_metadatas.find { |fm| fm.original_filename == ["city--spa.vtt"] }
        expect(spa_vtt.caption_language).to eq(["spa"])
        expect(spa_vtt.original_language_caption).to eq(false)
        expect(original_vtt.caption_language).to eq(["und"])
        expect(original_vtt.original_language_caption).to eq(true)
      end
    end

    context "when ingesting a RasterSet" do
      subject(:ingester) { described_class.new(change_set_persister: change_set_persister, logger: logger, klass: RasterResource) }
      it "ingests a RasterSet with file_sets marked as mosaic service targets" do
        ingester.attach_dir(
          base_directory: Rails.root.join("spec", "fixtures", "ingest_raster_set", "991234563506421")
        )
        raster_resource = ChangeSetPersister.default.query_service.find_all_of_model(model: RasterResource).find do |m|
          m.title == ["991234563506421"]
        end
        child_rasters = Wayfinder.for(raster_resource).members

        expect(child_rasters.map(&:class)).to eq [RasterResource, RasterResource]
        sheet1_children = Wayfinder.for(child_rasters.first).members
        sheet2_children = Wayfinder.for(child_rasters.last).members

        expect(sheet1_children.map(&:class)).to eq [FileSet]
        expect(sheet2_children.map(&:class)).to eq [FileSet]
        expect(sheet1_children.first.title).to eq ["sheet1"]
        expect(sheet2_children.first.title).to eq ["sheet2"]

        expect(sheet1_children.first.service_targets).to eq ["tiles"]
        expect(sheet2_children.first.service_targets).to eq ["tiles"]
      end
    end
    context "with a subdirectory named Raster" do
      subject(:ingester) { described_class.new(change_set_persister: change_set_persister, logger: logger, klass: ScannedMap) }
      it "ingests a RasterSet child" do
        stub_catalog(bib_id: "991234563506421")
        stub_catalog(bib_id: "991234567893506421")
        ingester.attach_dir(
          base_directory: Rails.root.join("spec", "fixtures", "ingest_scanned_raster_map", "991234563506421"),
          source_metadata_identifier: "991234563506421"
        )
        map = ChangeSetPersister.default.query_service.find_all_of_model(model: ScannedMap).find do |m|
          m.source_metadata_identifier == ["991234563506421"]
        end
        child_maps = Wayfinder.for(map).members

        expect(child_maps.map(&:class)).to eq [ScannedMap, ScannedMap]
        expect(child_maps.first.source_metadata_identifier).to eq ["991234567893506421"]
        expect(child_maps.first.title.first.to_s).to start_with "Earth rites"
        sheet1_children = Wayfinder.for(child_maps.first).members
        sheet2_children = Wayfinder.for(child_maps.last).members

        expect(sheet1_children.map(&:class)).to eq [RasterResource, FileSet]
        expect(sheet2_children.map(&:class)).to eq [RasterResource, FileSet]
        # Name sheets after folders so they appear named right in the viewer.
        expect(sheet1_children.last.title.first).to start_with "Earth rites"
        expect(sheet2_children.last.title).to eq ["Sheet2"]

        sheet1_raster_children = Wayfinder.for(sheet1_children.first).members
        sheet2_raster_children = Wayfinder.for(sheet2_children.first).members

        expect(sheet1_raster_children.map(&:class)).to eq [FileSet, FileSet]
        expect(sheet1_raster_children.first.title).to eq ["Raster"]
        expect(sheet1_raster_children.last.title).to eq ["Raster (Cropped)"]
        expect(sheet1_raster_children.last.service_targets).to eq ["tiles"]
        expect(sheet1_raster_children.first.service_targets).to eq []
        expect(sheet2_raster_children.map(&:class)).to eq [FileSet, FileSet]
        expect(sheet2_raster_children.first.title).to eq ["Raster"]
        expect(sheet2_raster_children.last.title).to eq ["Raster (Cropped)"]
        expect(sheet2_raster_children.last.service_targets).to eq ["tiles"]
        expect(sheet1_raster_children.first.service_targets).to eq []
      end
    end

    context "with invalid property arguments" do
      let(:logger) { instance_double(Logger) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "9946093213506421" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/9946093213506421/331" }

      before do
        allow(logger).to receive(:warn)
        allow(logger).to receive(:info)
        stub_catalog(bib_id: "9946093213506421")
        stub_ezid
      end

      it "does not ingest the resources and logs a warning" do
        ingester.attach_dir(
          base_directory: single_dir,
          property: "noexist",
          file_filters: [".tif"],
          source_metadata_identifier: bib
        )

        expect(logger).to have_received(:warn).with("Failed to find the resource for noexist:ingest_single")
        expect(logger).to have_received(:info).with(/Created the resource/)
      end
    end

    context "with a path to a non-existent directory" do
      it "raises an error" do
        expect { ingester.attach_each_dir(base_directory: "no/exist") }.to raise_error(ArgumentError, "BulkIngestService: Directory does not exist: no/exist")
      end
    end

    context "with a path to an empty directory" do
      let(:empty_dir) { Rails.root.join("spec", "fixtures", "empty") }
      before do
        Dir.mkdir(empty_dir)
      end
      after do
        Dir.rmdir(empty_dir)
      end
      it "raises an error" do
        expect { ingester.attach_each_dir(base_directory: empty_dir) }.to raise_error(ArgumentError, "BulkIngestService: Directory is empty: #{empty_dir}")
      end
    end
  end
end
