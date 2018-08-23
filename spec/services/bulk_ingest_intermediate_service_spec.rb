# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkIngestIntermediateService do
  subject(:service) { described_class.new(property: property, logger: logger, background: background) }

  let(:background) { false }
  let(:logger) { Logger.new(nil) }
  let(:property) { :source_metadata_identifier }
  let(:bib_id) { "123456" }
  let(:query_service) { metadata_adapter.query_service }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:ingest_intermediate_file_job) do
    class_double("IngestIntermediateFileJob").as_stubbed_const(transfer_nested_constants: true)
  end
  let(:directory) { Rails.root.join("spec", "fixtures", "files", "pudl0044", "originals_no_watermark", bib_id) }

  before do
    ingest_intermediate_file_job
  end

  describe "#ingest" do
    let(:base_directory) { Rails.root.join("spec", "fixtures", "files", "pudl0044", "originals_no_watermark") }
    let(:tiff_path) { File.join(directory, "intermediate.tiff") }

    before do
      allow(ingest_intermediate_file_job).to receive(:perform_now)
    end

    it "performs jobs for ingesting the intermediate file for each TIFF file in a directory" do
      service.ingest(base_directory)

      expect(ingest_intermediate_file_job).to have_received(:perform_now).with(tiff_path, property: property, value: bib_id)
    end
  end

  describe "#ingest_directory" do
    let(:tiff_path) { File.join(directory, "intermediate.tiff") }

    before do
      allow(ingest_intermediate_file_job).to receive(:perform_now)
    end

    it "performs jobs for ingesting the intermediate file for each TIFF file in a directory" do
      service.ingest_directory(directory: directory, property_value: bib_id)

      expect(ingest_intermediate_file_job).to have_received(:perform_now).with(tiff_path, property: property, value: bib_id)
    end

    context "when the service is performed in the background" do
      let(:background) { true }

      before do
        allow(ingest_intermediate_file_job).to receive(:set).and_return(ingest_intermediate_file_job)
        allow(ingest_intermediate_file_job).to receive(:perform_later)
      end

      it "enqueues the jobs to be performed" do
        service.ingest_directory(directory: directory, property_value: bib_id)

        expect(ingest_intermediate_file_job).to have_received(:set).at_least(1).times.with(queue: :low)
        expect(ingest_intermediate_file_job).to have_received(:perform_later).with(tiff_path, property: property, value: bib_id)
      end
    end
  end
end
