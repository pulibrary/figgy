# frozen_string_literal: true

require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NullCharacterizationService do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("mets/pudl0001-4612596.mets", "application/xml; schema=mets") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:sr) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:mets_members) { query_service.find_members(resource: sr) }
  let(:valid_file_set) { mets_members.first }

  it "properly no-ops on a mets metadata file" do
    file_set = valid_file_set
    new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.mime_type).to eq ["application/xml; schema=mets"]
  end

  describe "#valid?" do
    let(:file_set) { instance_double("FileSet") }
    let(:original_file) { instance_double("FileMetadata") }
    context "with a tiff" do
      before do
        allow(file_set).to receive(:original_file).and_return(original_file)
        allow(original_file).to receive(:mime_type).and_return(["image/tiff"])
      end

      it "returns false" do
        expect(described_class.new(file_set: file_set, persister: persister).valid?).to be false
      end
    end
    context "with a mets file" do
      before do
        allow(file_set).to receive(:original_file).and_return(original_file)
        allow(original_file).to receive(:mime_type).and_return(["application/xml; schema=mets"])
      end
      it "returns true" do
        expect(described_class.new(file_set: file_set, persister: persister).valid?).to be true
      end
    end
  end
end
