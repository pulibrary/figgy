# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestFolderJob do
  describe "#perform" do
    context "when given a multi-volume work to ingest into" do
      it "ingests" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        described_class.perform_now(directory: Rails.root.join("spec", "fixtures", "ingest_multi_simple"), property: :id, id: resource.id.to_s)

        resource = ChangeSetPersister.default.query_service.find_by(id: resource.id)
        expect(resource.member_ids.length).to eq 2
      end
    end

    context "when given a multi-volume work root with id-looking children" do
      it "ingests as a mvw" do
        stub_catalog(bib_id: "991234563506421")
        stub_catalog(bib_id: "10296", status: 404)
        described_class.perform_now(directory: Rails.root.join("spec", "fixtures", "mvw_small_ids", "991234563506421"))
      end
    end

    context "when given a single folder with TIFFs and a JPEG to ingest into" do
      it "ingests" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        described_class.perform_now(directory: Rails.root.join("spec", "fixtures", "ingest_single"), property: :id, id: resource.id.to_s)

        resource = ChangeSetPersister.default.query_service.find_by(id: resource.id)
        expect(resource.member_ids.length).to eq 3
      end
    end

    context "when using an unsupported class for ingesting files" do
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "9946093213506421" }
      let(:replaces) { "pudl0001/9946093213506421/331" }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
      before do
        allow(Rails.logger).to receive(:warn)
      end

      it "does not ingest any files and logs a warning" do
        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: single_dir,
          class_name: "EphemeraFolder",
          source_metadata_identifier: bib
        )

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: single_dir,
          property: nil,
          file_filters: [],
          source_metadata_identifier: bib
        )

        expect(Rails.logger).to have_received(:warn).with("Ingesting a folder with an unsupported class: EphemeraFolder")
      end
    end

    context "with a directory of Scanned TIFFs" do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "9946093213506421" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/9946093213506421/331" }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      it "ingests the resources" do
        coll = FactoryBot.create_for_repository(:collection)

        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: single_dir,
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id],
          depositor: "tpend"
        )

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: single_dir,
          property: nil,
          file_filters: [".tif", ".wav", ".pdf", ".zip", ".jpg", ".mp4"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id],
          depositor: "tpend"
        )
      end
    end

    context "with a SimpleChangeSet" do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "9946093213506421" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/9946093213506421/331" }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
      let(:class_name) { "ScannedResource" }
      let(:change_set_param) { "simple" }

      it "ingest the files as SimpleResource objects" do
        coll = FactoryBot.create_for_repository(:collection)

        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: single_dir,
          class_name: class_name,
          change_set_param: change_set_param,
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        expect(BulkIngestService).to have_received(:new).with(hash_including(klass: ScannedResource, change_set_param: "simple"))

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: single_dir,
          property: nil,
          file_filters: [".tif", ".wav", ".pdf", ".zip", ".jpg", ".mp4"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )
      end
    end

    context "with a video and caption file" do
      let(:ingest_dir) { Rails.root.join("spec", "fixtures", "av", "bulk_ingest", "video_with_captions") }
      it "ingests" do
        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: ingest_dir,
          title: "Interview"
        )

        expect(BulkIngestService).to have_received(:new).with(hash_including(klass: ScannedResource))

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: ingest_dir,
          property: nil,
          file_filters: [".tif", ".wav", ".pdf", ".zip", ".jpg", ".mp4"],
          title: "Interview"
        )
      end
    end
  end
end
