# frozen_string_literal: true
require "rails_helper"

RSpec.describe CheckFixityJob do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:file_set_id) { scanned_resource.member_ids.first }

  let(:file_metadata2) do
    FileMetadata.new(
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: "image/tiff",
      fixity_success: 1
    )
  end

  before do
    scanned_resource
    CharacterizationJob.perform_now(file_set_id.to_s)
  end

  describe "#perform" do
    # Note on spec setup. I tried to mock this without saving / checksuming actual
    # files. However, passing the id and the running fine on the id means you have
    # two different object instances and you cannot stub, e.g. :run_fixity
    it "saves the file_set" do
      fs = query_service.find_by(id: file_set_id)
      expect(fs.original_file.fixity_success).not_to eq 1

      described_class.perform_now(file_set_id)
      fs = query_service.find_by(id: file_set_id)
      expect(fs.original_file.fixity_success).to eq 1
    end

    context "when the file set does not exist" do
      let(:file_set_id) { "5f4235a3-53c0-42cc-9ada-564ea554264e" }
      before do
        allow(Valkyrie.logger).to receive(:warn)
        described_class.perform_now file_set_id
      end

      it "logs a warning" do
        expect(Valkyrie.logger).to have_received(:warn).with "#{described_class}: Valkyrie::Persistence::ObjectNotFoundError: Failed to find the resource #{file_set_id}"
      end
    end

    context "when FileNotFound on a non-orphaned file set" do
      it "raises a FileNotFound error" do
        allow(Valkyrie::StorageAdapter).to receive(:find_by).and_raise(Valkyrie::StorageAdapter::FileNotFound)

        expect { described_class.perform_now(file_set_id) }.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
      end
    end

    context "when FileNotFound on an orphaned file set" do
      it "deletes the fileset" do
        change_set = ChangeSet.for(scanned_resource)
        change_set_persister.delete(change_set: change_set)
        allow(Valkyrie::StorageAdapter).to receive(:find_by).and_raise(Valkyrie::StorageAdapter::FileNotFound)

        described_class.perform_now(file_set_id)

        expect { query_service.find_by(id: file_set_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end
end
