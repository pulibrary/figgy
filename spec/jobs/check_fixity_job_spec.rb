# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe CheckFixityJob do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
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
  end
end
