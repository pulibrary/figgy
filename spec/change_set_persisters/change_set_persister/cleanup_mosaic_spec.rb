# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::CleanupMosaic do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { instance_double(ChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { ChangeSet.for(resource) }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }
  # let(:file_identifiers) { [Valkyrie::ID.new("asdf")] }
  # let(:pdf_file) { FileMetadata.new mime_type: "application/pdf", file_identifiers: file_identifiers }

  before do
    allow(CleanupFilesJob).to receive(:perform_later)
  end

  describe "#run" do
    with_queue_adapter :inline

    context "with a non-mosaic Scanned Resource" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
      it "does nothing" do
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end

    context "with a non-mosaic Scanned Map" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_map_with_raster_child) }
      it "does nothing" do
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end

    context "with a non-mosaic RasterSet" do
      let(:resource) { FactoryBot.create_for_repository(:raster_set_with_one_raster_child) }
      it "does nothing" do
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end

    context "with a ScannedMap with multiple raster children" do
      let(:resource) { FactoryBot.create_for_repository(:map_set_with_raster_children) }
      it "runs job to remove the file" do
        hook.run

        expect(CleanupFilesJob).to have_received(:perform_later)
      end
    end

    context "with a RasterSet" do
      let(:resource) { FactoryBot.create_for_repository(:raster_set_with_files) }
      it "runs job to remove the file" do
        hook.run

        expect(CleanupFilesJob).to have_received(:perform_later)
      end
    end
  end
end
