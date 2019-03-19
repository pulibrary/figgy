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

      it "cleans up exisitng derivatives and generates new ones" do
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
  end
end
