# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestMapFolderJob do
  describe "#perform" do
    context "with a directory of Scanned TIFFs" do
      let(:logger) { Logger.new(nil) }
      let(:scanned_maps_dir) { Rails.root.join("spec", "fixtures", "ingest_scanned_maps") }
      let(:bib) { "9946093213506421" }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      it "ingests the map resources" do
        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: scanned_maps_dir,
          source_metadata_identifier: bib
        )

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: scanned_maps_dir,
          file_filters: [".tif"],
          source_metadata_identifier: bib
        )
      end
    end
  end
end
