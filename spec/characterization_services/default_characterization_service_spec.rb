# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"
include ActionDispatch::TestProcess

RSpec.describe DefaultCharacterizationService do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:book) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:book_members) { query_service.find_members(resource: book) }
  let(:valid_file_set) { book_members.first }

  it "properly characterizes a sample tiff" do
    file_set = valid_file_set
    file_set.original_file.height = nil
    new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.height).not_to be_empty
  end

  describe "#valid?" do
    let(:decorator) { instance_double(FileSetDecorator, parent: parent) }

    before do
      allow(valid_file_set).to receive(:decorate).and_return(decorator)
    end

    context "with a scanned map parent" do
      let(:parent) { ScannedMap.new }
      it "isn't valid" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be false
      end
    end
  end
end
