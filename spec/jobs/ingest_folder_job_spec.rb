# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestFolderJob do
  describe "#perform" do
    context "with a directory of Scanned TIFFs" do
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
          directory: single_dir,
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: single_dir,
          property: nil,
          file_filter: ".tif",
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )
      end
    end
<<<<<<< HEAD

    context "with a SimpleResource model" do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:bib) { "4609321" }
      let(:local_id) { "cico:xyz" }
      let(:replaces) { "pudl0001/4609321/331" }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
      let(:class_name) { "SimpleResource" }

      it "ingest the files as SimpleResource objects" do
        coll = FactoryBot.create_for_repository(:collection)

        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: single_dir,
          class_name: class_name,
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )

        expect(BulkIngestService).to have_received(:new).with(hash_including(klass: SimpleResource))

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: single_dir,
          property: nil,
          file_filter: ".tif",
          source_metadata_identifier: bib,
          local_identifier: local_id,
          member_of_collection_ids: [coll.id]
        )
      end
    end
=======
>>>>>>> d8616123... adds lux order manager to figgy
  end
end
