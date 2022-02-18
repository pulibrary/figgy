# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateChecksumJob do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:file_set_id) { scanned_resource.member_ids.first }

  describe "#perform" do
    it "generates and saves a checksum for the file" do
      fs = query_service.find_by(id: file_set_id)
      expect(fs.original_file.checksum.first).to be_nil

      described_class.perform_now(file_set_id)
      fs = query_service.find_by(id: file_set_id)
      expect(fs.original_file.checksum.first.md5).to eq "2a28fb702286782b2cbf2ed9a5041ab1"
    end
  end
end
