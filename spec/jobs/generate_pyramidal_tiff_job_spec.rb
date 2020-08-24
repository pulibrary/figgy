# frozen_string_literal: true
require "rails_helper"

RSpec.describe GeneratePyramidalTiffJob do
  describe "#perform" do
    context "with a valid file set id" do
      with_queue_adapter :inline
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
      it "cleans up existing pyramidal derivatives and generates new ones", run_real_derivatives: true, run_real_characterization: true do
        resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
        file_set = Wayfinder.for(resource).file_sets[0]
        pyramidal_derivative = file_set.pyramidal_derivative

        described_class.perform_now(file_set.id.to_s)

        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: file_set.id)
        expect(reloaded.pyramidal_derivative.id).not_to eq pyramidal_derivative.id
        expect(reloaded.file_metadata.length).to eq 2
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
