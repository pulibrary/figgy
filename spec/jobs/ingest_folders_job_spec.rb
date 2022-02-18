# frozen_string_literal: true

require "rails_helper"

RSpec.describe IngestFoldersJob do
  describe "#perform" do
    context "with a directory of Scanned TIFFs" do
      let(:logger) { Logger.new(nil) }
      let(:multi_dir) { Rails.root.join("spec", "fixtures", "ingest_multi") }
      let(:property) { "barcode" }
      let(:filters) { [".tif", ".wav"] }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      it "ingests the directories of resources" do
        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_each_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: multi_dir,
          property: property,
          file_filters: filters
        )

        expect(ingest_service).to have_received(:attach_each_dir).with(
          base_directory: Pathname.new(multi_dir),
          property: property,
          file_filters: filters
        )
      end

      context "without file filters being specified" do
        it "generates the filters using the class name" do
          ingest_service = instance_double(BulkIngestService)
          allow(ingest_service).to receive(:attach_each_dir)
          allow(BulkIngestService).to receive(:new).and_return(ingest_service)

          described_class.perform_now(
            directory: multi_dir,
            property: property
          )

          expect(ingest_service).to have_received(:attach_each_dir).with(
            base_directory: Pathname.new(multi_dir),
            property: property,
            file_filters: filters
          )
        end
      end
    end

    context "with a SimpleResource model" do
      let(:logger) { Logger.new(nil) }
      let(:multi_dir) { Rails.root.join("spec", "fixtures", "ingest_multi") }
      let(:property) { "barcode" }
      let(:filters) { [".tif", ".wav"] }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
      let(:class_name) { "ScannedResource" }
      let(:change_set) { "simple" }

      it "ingest the directory files as SimpleResource objects" do
        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_each_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: multi_dir,
          class_name: class_name,
          property: property,
          file_filters: filters,
          change_set_param: change_set
        )

        expect(BulkIngestService).to have_received(:new).with(hash_including(klass: ScannedResource, change_set_param: "simple"))

        expect(ingest_service).to have_received(:attach_each_dir).with(
          base_directory: Pathname.new(multi_dir),
          property: property,
          file_filters: filters
        )
      end
    end
  end

  context "when using an unsupported class for ingesting files" do
    let(:multi_dir) { Rails.root.join("spec", "fixtures", "ingest_multi") }
    let(:property) { "barcode" }

    before do
      allow(Rails.logger).to receive(:warn)
    end

    it "does not ingest any files and logs a warning" do
      ingest_service = instance_double(BulkIngestService)
      allow(ingest_service).to receive(:attach_each_dir)
      allow(BulkIngestService).to receive(:new).and_return(ingest_service)

      described_class.perform_now(
        directory: multi_dir,
        class_name: "EphemeraFolder",
        property: property
      )

      expect(ingest_service).to have_received(:attach_each_dir).with(
        base_directory: Pathname.new(multi_dir),
        property: property,
        file_filters: []
      )

      expect(Rails.logger).to have_received(:warn).with("Ingesting a folder with an unsupported class: EphemeraFolder")
    end
  end
end
