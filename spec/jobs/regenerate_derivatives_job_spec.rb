# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegenerateDerivativesJob do
  describe "#perform" do
    context "with a valid file set id" do
      let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      let(:generator) { instance_double(EventGenerator, derivatives_deleted: nil, derivatives_created: nil) }

      before do
        allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).with(id: file_set.id).and_return(derivatives_service)
        allow(derivatives_service).to receive(:create_derivatives)
        allow(derivatives_service).to receive(:cleanup_derivatives)
        allow(EventGenerator).to receive(:new).and_return(generator)
      end

      it "cleans up existing derivatives and generates new ones" do
        described_class.perform_now(file_set.id)
        expect(derivatives_service).to have_received(:cleanup_derivatives)
        expect(derivatives_service).to have_received(:create_derivatives)
      end
    end

    context "with an invalid file set id" do
      let(:logger) { instance_double(ActiveSupport::Logger) }

      before do
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error)
      end

      it "logs the exception" do
        described_class.perform_now("bogus")
        expect(logger).to have_received(:error)
      end
    end

    context "with a pdf preservation master", run_real_characterization: true, run_real_derivatives: true do
      with_queue_adapter :inline
      let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
      let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
      let(:storage_adapter) { Valkyrie.config.storage_adapter }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
      let(:query_service) { adapter.query_service }
      let(:scanned_resource) do
        change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
      end
      let(:book_members) { query_service.find_members(resource: scanned_resource) }
      let(:valid_resource) { book_members.first }
      let(:pdf_derivative_service) do
        PDFDerivativeService.new(id: valid_resource.id, change_set_persister: change_set_persister)
      end
      let(:generator) { instance_double(EventGenerator, derivatives_deleted: nil, derivatives_created: nil) }

      before do
        valid_resource
        allow(PDFDerivativeService).to receive(:new).and_return(pdf_derivative_service)
        allow(pdf_derivative_service).to receive(:valid?).and_call_original
        allow(pdf_derivative_service).to receive(:create_derivatives)
        allow(pdf_derivative_service).to receive(:cleanup_derivatives)
        allow(EventGenerator).to receive(:new).and_return(generator)
      end

      it "cleans up existing intermediate files and generates new ones" do
        described_class.perform_now(valid_resource.id)
        expect(pdf_derivative_service).to have_received(:cleanup_derivatives)
        expect(pdf_derivative_service).to have_received(:create_derivatives)
      end
    end
  end
end
