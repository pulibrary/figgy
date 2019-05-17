# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe RegenerateDerivativesJob do
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }

  describe "#perform" do
    context "with a valid file set id" do
      let(:derivatives_service) { instance_double(Valkyrie::Derivatives::DerivativeService) }
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
        expect(Rails.logger).to have_received(:error).with("Failed to regenerate the derivatives for #{file_set.id}: MiniMagick::Error")

        expect(derivatives_service).to have_received(:cleanup_derivatives).once
        expect(derivatives_service).to have_received(:create_derivatives).once
        expect(described_class).to have_received(:perform_later)
      end
    end
  end

  context "with ImageMagick uninstalled on your MacBook" do
    let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file_set) { scanned_resource.decorate.file_sets.first }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:query_service) { adapter.query_service }

    it "propagates an ImageMagick error", run_real_derivatives: true do
      expect { described_class.perform_now(file_set.id.to_s) }.to raise_error(MiniMagick::Invalid)
    end
  end
end
