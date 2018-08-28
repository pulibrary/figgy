# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::CleanupDerivatives do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { instance_double(ChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { DynamicChangeSet.new(resource) }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }
  let(:pdf_file) { FileMetadata.new mime_type: "application/pdf", file_identifiers: [Valkyrie::ID.new("asdf")] }

  before do
    allow(CleanupFilesJob).to receive(:perform_later)
  end

  describe "#run" do
    context "with a resource that isn't a ScannedResource" do
      let(:resource) { FactoryBot.create(:draft_simple_resource) }
      it "does nothing" do
        change_set.prepopulate!
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end
    context "with a ScannedResource without a PDF attached" do
      let(:resource) { FactoryBot.create(:scanned_resource) }
      it "does nothing" do
        change_set.prepopulate!
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end
    context "with a ScannedResource with a PDF attached and no changes other than a PDF being attached" do
      let(:resource) { FactoryBot.create(:scanned_resource) }
      it "does nothing" do
        change_set.prepopulate!
        change_set.validate(file_metadata: [pdf_file])
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end
    context "with a ScannedResource with a PDF attached and changes" do
      let(:resource) { FactoryBot.create(:scanned_resource, file_metadata: [pdf_file]) }
      it "deletes the PDF and removes it from the ScannedResource" do
        change_set.prepopulate!
        change_set.validate(title: "Updated resource")
        hook.run

        expect(CleanupFilesJob).to have_received(:perform_later).with(file_identifiers: ["asdf"])
        expect(resource.file_metadata).to eq []
      end
    end
  end
end
