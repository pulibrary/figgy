# frozen_string_literal: true
require "rails_helper"

RSpec.describe RemoteChecksumJob do
  #   let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }
  #   let(:fixity_job) { instance_double(CheckFixityJob) }
  #   let(:generator) { EventGenerator.new }
  #
  #   before do
  #     allow(Valkyrie::Derivatives::DerivativeService).to receive(:for).and_return(derivatives_service)
  #     allow(derivatives_service).to receive(:create_derivatives)
  #     allow(EventGenerator).to receive(:new).and_return(generator)
  #     allow(generator).to receive(:derivatives_created).and_call_original
  #     allow(CheckFixityJob).to receive(:set).and_return(CheckFixityJob)
  #   end

  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  describe "#perform_now" do
    it "triggers a derivatives_created message", rabbit_stubbed: true do
      described_class.perform_now(file_set.id.to_s)

      expect(file_set.remote_checksum).to eq "foo"
    end
  end
end
