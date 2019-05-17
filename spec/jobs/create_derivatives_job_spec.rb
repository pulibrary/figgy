# frozen_string_literal: true
require "rails_helper"

RSpec.describe CreateDerivativesJob do
  let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:fixity_job) { instance_double(CheckFixityJob) }
  let(:generator) { EventGenerator.new }

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

    context "when an ImageMagick error is raised" do
      let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(derivatives_service).to receive(:create_derivatives).and_raise(MiniMagick::Error)
        allow(derivatives_service).to receive(:cleanup_derivatives)
        allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).with(id: file_set.id).and_return(derivatives_service)
        allow(described_class).to receive(:perform_later)
      end

      it "logs and error and retries the job" do
        described_class.perform_now(file_set.id)
        expect(Rails.logger).to have_received(:error).with("Failed to create the derivatives for #{file_set.id}: MiniMagick::Error")

        expect(derivatives_service).to have_received(:create_derivatives).once
        expect(described_class).to have_received(:perform_later)
      end
    end
  end
end
