# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "ScannedMaps", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:scanned_map) do
    res = FactoryBot.create_for_repository(:scanned_map)
    persister.save(resource: res)
  end
  let(:change_set) do
    ScannedMapChangeSet.new(scanned_map)
  end
  let(:change_set_persister) do
    PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    change_set.sync
    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  scenario 'creating a new resource' do
    visit new_scanned_map_path

    expect(page).to have_field 'Title'
    expect(page).not_to have_css '.mutex[name="scanned_map[title][]"]'
    expect(page).to have_field 'Source Metadata ID'
    expect(page).not_to have_css '.mutex[name="scanned_map[source_metadata_identifier]"'
    expect(page).to have_css '.select[for="scanned_map_rights_statement"]', text: 'Rights Statement'
    expect(page).to have_field 'Rights Note'
    expect(page).to have_field 'Local identifier'
    expect(page).to have_css '.select[for="scanned_map_holding_location"]', text: 'Holding Location'
    expect(page).to have_css '.select[for="scanned_map_member_of_collection_ids"]', text: 'Collections'
    expect(page).not_to have_css '.control-label[for="scanned_map_coverage"]', text: 'Coverage'
    expect(page).to have_field 'Description'
    expect(page).to have_field 'Subject'
    expect(page).to have_field 'Spatial'
    expect(page).to have_field 'Temporal'
    expect(page).to have_field 'Issued'
    expect(page).to have_field 'Creator'
    expect(page).to have_field 'Language'
    expect(page).to have_field 'Cartographic scale'
  end
end
