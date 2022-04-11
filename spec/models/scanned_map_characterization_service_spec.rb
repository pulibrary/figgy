# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe ScannedMapCharacterizationService do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:map_members) { query_service.find_members(resource: map) }
  let(:valid_file_set) { map_members.first }

  describe "#characterize" do
    it "sets the processing note attribute for a file_set on characterize" do
      t_file_set = valid_file_set
      t_file_set.original_file.width = nil
      new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.processing_note).not_to be_empty
    end
  end

  describe "#valid?" do
    let(:subject) { described_class.new(file_set: valid_file_set, persister: persister).valid? }

    it { is_expected.to be true }
  end
end
