# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::CleanupPDFDerivatives do
  with_queue_adapter :inline
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: subject_change_set) }
  let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:subject_change_set) { ChangeSet.for(fileset) }
  let(:fileset) { Wayfinder.for(scanned_resource).members.first }
  let(:query_service) { adapter.query_service }
  let(:resource_change_set) { ChangeSet.for(FactoryBot.create(:scanned_resource), files: [file]) }
  let(:scanned_resource) do
    ChangeSetPersister.default.save(change_set: resource_change_set)
  end

  describe "#run" do
    context "with a PDF fileset" do
      it "deletes the derivatives" do
        scanned_resource
        allow(change_set_persister).to receive(:save).and_call_original
        hook.run
        expect(change_set_persister).to have_received(:save).at_least(:once)
        expect(Wayfinder.for(scanned_resource).members.count).to eq(1)
      end
    end

    context "with two tiff filesets" do
      let(:file1) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:resource_change_set) { ChangeSet.for(FactoryBot.create(:scanned_resource), files: [file1, file2]) }

      it "doesn't run" do
        scanned_resource
        allow(change_set_persister).to receive(:save)
        hook.run
        expect(change_set_persister).not_to have_received(:save)
        expect(Wayfinder.for(scanned_resource).members.count).to eq(2)
      end
    end

    context "with a ScannedResource" do
      let(:subject_change_set) { ChangeSet.for(scanned_resource) }
      it "doesn't run" do
        scanned_resource
        allow(change_set_persister).to receive(:save)
        hook.run
        expect(change_set_persister).not_to have_received(:save)
        expect(Wayfinder.for(scanned_resource).members.count).to eq(3)
      end
    end
  end
end
