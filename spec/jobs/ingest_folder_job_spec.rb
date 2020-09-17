# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestFolderJob do
  describe "#perform" do
    context "when using an unsupported class for ingesting files" do
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "4609321" }
      let(:replaces) { "pudl0001/4609321/331" }
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
          directory: [single_dir],
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

    context "with one or more directories of Scanned TIFFs" do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "4609321" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/4609321/331" }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      it "ingests the resources" do
        coll = FactoryBot.create_for_repository(:collection)

        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: [single_dir],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: single_dir,
          property: nil,
          file_filters: [".tif", ".wav", ".pdf"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )
      end
    end

    context "with a SimpleChangeSet" do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "4609321" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/4609321/331" }
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
          directory: [single_dir],
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
          file_filters: [".tif", ".wav", ".pdf"],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )
      end
    end
  end
end
