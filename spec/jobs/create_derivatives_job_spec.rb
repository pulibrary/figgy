# frozen_string_literal: true
require 'rails_helper'

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
    allow(CheckFixityJob).to receive(:perform_later)
  end

  describe "#perform_now" do
    it "triggers a derivatives_created message and triggers a fixity job", rabbit_stubbed: true do
      described_class.perform_now(file_set.id)
      expect(generator).to have_received(:derivatives_created)
      expect(CheckFixityJob).to have_received(:perform_later)
    end
  end
end
