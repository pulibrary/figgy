# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::CleanupPdfs do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { instance_double(ChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { ChangeSet.for(resource) }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }
  let(:file_identifiers) { [Valkyrie::ID.new("asdf")] }
  let(:pdf_file) { FileMetadata.new mime_type: "application/pdf", file_identifiers: file_identifiers }

  before do
    allow(CleanupFilesJob).to receive(:perform_later)
  end

  describe "#run" do
    context "with a resource that isn't a ScannedResource or a ScannedMap" do
      let(:resource) { FactoryBot.create(:draft_simple_resource) }
      it "does nothing" do
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end
    context "with a ScannedResource without a PDF attached" do
      let(:resource) { FactoryBot.create(:scanned_resource) }
      it "does nothing" do
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end
    context "with a ScannedResource with a PDF attached and no changes other than a PDF being attached" do
      let(:resource) { FactoryBot.create(:scanned_resource) }
      it "does not remove the files" do
        change_set.validate(file_metadata: [pdf_file])
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end
    context "with a ScannedResource with PDF metadata attached with missing files" do
      let(:file_identifiers) { [] }
      let(:resource) { FactoryBot.create(:scanned_resource, file_metadata: [pdf_file]) }
      before do
        allow(Valkyrie.logger).to receive(:error)
      end
      it "removes the metadata and does not attempt to delete the missing files" do
        change_set.validate(file_metadata: [pdf_file])
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
        expect(resource.file_metadata).to eq []
        expect(Valkyrie.logger).to have_received(:error).with(/Failed to locate the file for the PDF FileMetadata/)
      end
    end
    context "with a ScannedResource with PDF metadata attached with existing files" do
      let(:file_identifiers) { [Valkyrie::ID.new("disk://#{File.expand_path(__FILE__)}")] }
      let(:resource) { FactoryBot.create(:scanned_resource, file_metadata: [pdf_file]) }
      it "keeps the metadata and does not attempt to delete the missing files" do
        change_set.validate(file_metadata: [pdf_file])
        hook.run

        expect(CleanupFilesJob).not_to have_received(:perform_later)
        expect(resource.file_metadata).to eq [pdf_file]
      end
    end
    context "with a ScannedResource with a PDF attached and changes" do
      let(:resource) { FactoryBot.create(:scanned_resource, file_metadata: [pdf_file]) }
      it "deletes the PDF and removes it from the ScannedResource" do
        change_set.validate(title: "Updated resource")
        hook.run

        expect(CleanupFilesJob).to have_received(:perform_later).with(file_identifiers: ["asdf"])
        expect(resource.file_metadata).to eq []
      end
    end
    context "with a ScannedMap with a PDF attached and changes" do
      let(:resource) { FactoryBot.create(:scanned_map, file_metadata: [pdf_file]) }
      it "deletes the PDF and removes it from the ScannedMap" do
        change_set.validate(title: "Updated resource")
        hook.run

        expect(CleanupFilesJob).to have_received(:perform_later).with(file_identifiers: ["asdf"])
        expect(resource.file_metadata).to eq []
      end
    end
  end
end
