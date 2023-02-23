# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::CleanupPDFDerivatives do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:change_set) { ChangeSet.for(fileset) }
  let(:fileset) { Wayfinder.for(scanned_resource).members.first }
  let(:query_service) { adapter.query_service }
  let(:scanned_resource) do
    ChangeSetPersister.default.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end

  describe "#run" do
    with_queue_adapter :inline
    context "with a PDF fileset" do
      it "deletes the derivatives" do
        allow(change_set_persister).to receive(:save).and_call_original
        scanned_resource
        hook.run
        expect(change_set_persister).to have_received(:save).at_least(:once)
      end
    end

    context "with two tiff filesets" do
      let(:file1) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:scanned_resource) do
        change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file1, file2]))
      end

      it "doesn't run" do
        allow(change_set_persister).to receive(:save).and_call_original
        scanned_resource
        hook.run
        expect(change_set_persister).not_to have_received(:save)
      end
    end

    context "with a ScannedResource" do
      let(:change_set) { ChangeSet.for(scanned_resource) }
      it "doesn't run" do
        allow(change_set_persister).to receive(:save).and_call_original
        scanned_resource
        hook.run
        expect(change_set_persister).not_to have_received(:save)
      end
    end
  end
end
