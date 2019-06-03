# frozen_string_literal: true
require "rails_helper"

RSpec.describe CreateDerivativesJob do
  let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:fixity_job) { instance_double(CheckFixityJob) }
  let(:generator) { EventGenerator.new }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }

  before do
    allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_return(derivatives_service)
    allow(derivatives_service).to receive(:create_derivatives)
    allow(EventGenerator).to receive(:new).and_return(generator)
    allow(generator).to receive(:derivatives_created).and_call_original
    allow(CheckFixityJob).to receive(:set).and_return(CheckFixityJob)
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
        allow(jp2_derivative_service).to receive(:create_derivatives).and_raise(MiniMagick::Error)
        allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_return(jp2_derivative_service)
        allow(Valkyrie.logger).to receive(:error)
      end

      it "logs the error and cleans up the derivatives" do
        expect { described_class.perform_now(file_set.id.to_s) }.to raise_error(MiniMagick::Error)
        expect(jp2_derivative_service).to have_received(:cleanup_derivatives).once
        reloaded = query_service.find_by(id: file_set.id)
        expect(reloaded.thumbnail_files).to be_empty

        expect(Valkyrie.logger).to have_received(:error).with(/Failed to generate derivatives for #{file_set.id}: MiniMagick::Error/)
      end
    end

    context "when the JP2000 derivative generation raises a generic error" do
      let(:jp2_derivative_service) { instance_double(Jp2DerivativeService) }
      let(:jp2_derivative_service_factory) { instance_double(Jp2DerivativeService::Factory) }

      before do
        allow(jp2_derivative_service).to receive(:cleanup_derivatives)
        allow(jp2_derivative_service).to receive(:create_derivatives).and_raise(Valkyrie::Persistence::StaleObjectError, "The object foo has been updated by another process.")
        allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_return(jp2_derivative_service)
        allow(Valkyrie.logger).to receive(:error)
      end

      it "logs the error and cleans up the derivatives" do
        expect { described_class.perform_now(file_set.id.to_s) }.to raise_error(Valkyrie::Persistence::StaleObjectError)
        expect(jp2_derivative_service).to have_received(:cleanup_derivatives).once
        reloaded = query_service.find_by(id: file_set.id)
        expect(reloaded.thumbnail_files).to be_empty

        expect(Valkyrie.logger).to have_received(:error).with("Failed to generate derivatives for #{file_set.id}: Valkyrie::Persistence::StaleObjectError: The object foo has been updated by another process.")
      end
    end
  end
end
