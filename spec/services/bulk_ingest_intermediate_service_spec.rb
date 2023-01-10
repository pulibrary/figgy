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

  context "when the resource cannot be found" do
    describe "#ingest" do
      let(:base_directory) { Rails.root.join("spec", "fixtures", "files", "pudl0044", "originals_no_watermark") }

      before do
        allow(ingest_intermediate_file_job).to receive(:perform_now)
      end

      it "performs jobs for ingesting the intermediate file for each TIFF file in a directory" do
        expect { service.ingest(base_directory) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end

  context "when a resource exists" do
    let(:primary_file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: bib_id, files: [primary_file]) }
    let(:file_set) { resource.decorate.decorated_file_sets.first }

    before do
      stub_catalog(bib_id: "123456")
      resource
    end

    describe "#ingest" do
      let(:base_directory) { Rails.root.join("spec", "fixtures", "files", "pudl0044", "originals_no_watermark") }
      let(:tiff_path) { File.join(directory, "00000001.tif") }

      before do
        allow(ingest_intermediate_file_job).to receive(:perform_now)
      end

      it "performs jobs for ingesting the intermediate file for each TIFF file in a directory" do
        service.ingest(base_directory)

        expect(ingest_intermediate_file_job).to have_received(:perform_now).with(file_path: tiff_path, file_set_id: file_set.id.to_s)
      end
    end

    context "when requesting that the job be performed asynchronously" do
      let(:background) { true }

      let(:base_directory) { Rails.root.join("spec", "fixtures", "files", "pudl0044", "originals_no_watermark") }
      let(:tiff_path) { File.join(directory, "00000001.tif") }

      before do
        allow(ingest_intermediate_file_job).to receive(:set).and_return(ingest_intermediate_file_job)
        allow(ingest_intermediate_file_job).to receive(:perform_later)
      end

      it "performs jobs for ingesting the intermediate file for each TIFF file in a directory" do
        service.ingest(base_directory)

        expect(ingest_intermediate_file_job).to have_received(:set).with(queue: :low)
        expect(ingest_intermediate_file_job).to have_received(:perform_later).with(file_path: tiff_path, file_set_id: file_set.id.to_s)
      end
    end

    context "when a file does not have a numeric index" do
      let(:base_directory) { Rails.root.join("spec", "fixtures", "files", "pudl0044", "originals_no_watermark") }
      let(:tiff_path) { File.join(directory, "00000001.tif") }

      before do
        allow(ingest_intermediate_file_job).to receive(:perform_now)
        allow(Dir).to receive(:[]).with("#{base_directory}/*").and_call_original
        allow(Dir).to receive(:[]).with("#{directory}/*{tif,jpg}*").and_return(["#{directory}/invalid.tif"])
        allow(logger).to receive(:warn)
      end

      it "does not perform the job and logs a warning" do
        service.ingest(base_directory)

        expect(ingest_intermediate_file_job).not_to have_received(:perform_now)
        expect(logger).to have_received(:warn).with("Failed to parse the index integer from #{directory}/invalid.tif")
      end
    end

    context "when a file has a numeric index out of order" do
      let(:base_directory) { Rails.root.join("spec", "fixtures", "files", "pudl0044", "originals_no_watermark") }
      let(:tiff_path) { File.join(directory, "00000001.tif") }

      before do
        allow(ingest_intermediate_file_job).to receive(:perform_now)
        allow(Dir).to receive(:[]).with("#{base_directory}/*").and_call_original
        allow(Dir).to receive(:[]).with("#{directory}/*{tif,jpg}*").and_return(["#{directory}/00000009.tif"])
        allow(logger).to receive(:warn)
      end

      it "does not perform the job and logs a warning" do
        service.ingest(base_directory)

        expect(ingest_intermediate_file_job).not_to have_received(:perform_now)
        expect(logger).to have_received(:warn).with("Failed to map #{directory}/00000009.tif to a FileSet for the Resource #{resource.id}")
      end
    end
  end
end
