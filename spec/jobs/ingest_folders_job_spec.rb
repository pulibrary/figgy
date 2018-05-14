# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestFoldersJob do
  describe "#perform" do
    context "with a directory of Scanned TIFFs" do
      let(:logger) { Logger.new(nil) }
      let(:multi_dir) { Rails.root.join("spec", "fixtures", "ingest_multi") }
      let(:property) { "barcode" }
      let(:filter) { ".tif" }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      it "ingests the directories of resources" do
        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_each_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: multi_dir,
          property: property,
          file_filter: filter
        )

        expect(ingest_service).to have_received(:attach_each_dir).with(
          base_directory: Pathname.new(multi_dir),
          property: property,
          file_filter: filter
        )
      end
    end
  end
end
