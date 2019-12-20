# frozen_string_literal: true
require "rails_helper"

RSpec.describe CreateDerivativesJob do
  let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }
  let(:file) { fixture_file_upload("files/holding_locations.json", "image/tiff") }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
  end
  let(:file_set) do
    scanned_resource.decorate.file_sets.first
  end
  let(:fixity_job) { instance_double(CheckFixityJob) }
  let(:generator) { EventGenerator.new }

  before do
    allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_return(derivatives_service)
    allow(derivatives_service).to receive(:create_derivatives)
    allow(EventGenerator).to receive(:new).and_return(generator)
    allow(generator).to receive(:derivatives_created).and_call_original
    allow(CheckFixityJob).to receive(:set).and_return(CheckFixityJob)
    stub_ezid(shoulder: "99999/fk4", blade: "1234567")
  end

  describe "#perform_now" do
    it "triggers a derivatives_created message", rabbit_stubbed: true do
      described_class.perform_now(file_set.id.to_s)
      expect(generator).to have_received(:derivatives_created)
    end

    it "enqueues a fixity job", rabbit_stubbed: true do
      expect { described_class.perform_now(file_set.id.to_s) }.to have_enqueued_job(CheckFixityJob)
    end

    it "does not error with a non-existent file_set_id" do
      expect { described_class.perform_now("blabla") }.not_to raise_error
    end

    context "when the JP2000 derivative generation raises an ImageMagick error" do
      let(:jp2_derivative_service) { instance_double(Jp2DerivativeService) }
      let(:jp2_derivative_service_factory) { instance_double(Jp2DerivativeService::Factory) }

      before do
        allow(jp2_derivative_service).to receive(:cleanup_derivatives)
        allow(jp2_derivative_service).to receive(:create_derivatives).and_raise(MiniMagick::Error, "ImageMagick/GraphicsMagick is not installed")
        allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_return(jp2_derivative_service)
        allow(Valkyrie.logger).to receive(:error)

        described_class.perform_now(file_set.id.to_s)
      end

      it "logs the error and cleans up the derivatives" do
        expect(jp2_derivative_service).to have_received(:cleanup_derivatives).once
        reloaded = query_service.find_by(id: file_set.id)
        expect(reloaded.thumbnail_files).to be_empty

        expect(Valkyrie.logger).to have_received(:error).with("Failed to generate derivatives for #{file_set.id}: MiniMagick::Error: ImageMagick/GraphicsMagick is not installed")
      end
    end

    context "when the JP2000 derivative generation raises a generic error", run_real_derivatives: true do
      with_queue_adapter :inline
      let(:jp2_derivative_service) { instance_double(Jp2DerivativeService) }
      let(:jp2_derivative_service_factory) { instance_double(Jp2DerivativeService::Factory) }

      before do
        allow(jp2_derivative_service).to receive(:cleanup_derivatives)
        allow(jp2_derivative_service).to receive(:create_derivatives).and_raise(Valkyrie::Persistence::StaleObjectError, "The object foo has been updated by another process.")
        allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_call_original
        allow(Valkyrie.logger).to receive(:error)
      end

      it "logs the error and cleans up the derivatives" do
        file_set
        reloaded = query_service.find_by(id: scanned_resource.id)
        persisted_file_set = reloaded.decorate.file_sets.first
        expect(persisted_file_set.thumbnail_files).to be_empty

        expect(Valkyrie.logger).to have_received(:error).with(/Failed to generate derivatives for #{file_set.id}: MiniMagick::Invalid/)
      end
    end
  end
end
