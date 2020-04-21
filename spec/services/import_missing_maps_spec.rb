# frozen_string_literal: true
require "rails_helper"

RSpec.describe ImportMissingMaps do
  with_queue_adapter :inline
  subject(:importer) { described_class }

  let(:depositor) { FactoryBot.create(:admin) }
  let(:file_root) { Rails.root.join("spec", "fixtures", "maps") }
  let(:csv_path) { "spec/fixtures/files/trenton.csv" }
  let(:scanned_map_id) { scanned_map.id }

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new))
  end
  let(:scanned_map_members) { query_service.find_members(resource: scanned_map) }

  describe ".import", run_real_derivatives: true do
    before do
      stub_bibdata(bib_id: "123456")
      scanned_map
    end

    it "imports from CSV" do
      importer.import_map_set(csv_path: csv_path, parent_id: scanned_map_id, file_root: file_root, depositor: depositor)
      parent = query_service.find_by(id: scanned_map_id)
      members = parent.decorate.members
      expect(members.count).to eq 2
      expect(members.first.decorate.file_sets.count).to eq 1
    end
  end
end
