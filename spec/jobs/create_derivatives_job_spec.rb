# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateDerivativesJob do
  let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:generator) { EventGenerator.new }

  before do
    allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_return(derivatives_service)
    allow(derivatives_service).to receive(:create_derivatives)
    allow(EventGenerator).to receive(:new).and_return(generator)
    allow(generator).to receive(:derivatives_created).and_call_original
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

    context "when the file is not found" do
      it "does not error" do
        allow(derivatives_service).to receive(:create_derivatives).and_raise(Valkyrie::StorageAdapter::FileNotFound)
        expect { described_class.perform_now(file_set.id.to_s) }.not_to raise_error
      end
    end
  end
end
