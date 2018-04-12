# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "SimpleResources", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:simple_resource) do
    res = FactoryBot.create_for_repository(:simple_resource)
    persister.save(resource: res)
  end
  let(:change_set) do
    SimpleResourceChangeSet.new(simple_resource)
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
    visit new_simple_resource_path

    expect(page).to have_field 'Title'
    expect(page).to have_field 'Rights Statement'
    expect(page).to have_field 'Rights Note'
    expect(page).to have_field 'Local identifier'
    expect(page).to have_field 'PDF Type'
    expect(page).to have_field 'Portion Note'
    expect(page).to have_field 'Navigation Date'
    expect(page).to have_field 'Collections'
  end

  context 'when a user creates a new simple resource' do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:simple_resource) do
      FactoryBot.create_for_repository(
        :simple_resource,
        title: 'new simple resource',
        rights_statement: 'http://rightsstatements.org/vocab/CNE/1.0/',
        rights_note: 'test rights note',
        local_identifier: 'test ID',
        portion_note: 'test portion note',
        nav_date: 'test navigation date',
        member_of_collection_ids: [collection.id]
      )
    end

    scenario 'viewing a resource' do
      visit solr_document_path simple_resource

      expect(page).to have_css '.attribute.title', text: 'new simple resource'
      expect(page).to have_css '.attribute.rights_statement', text: 'http://rightsstatements.org/vocab/CNE/1.0/'
      expect(page).to have_css '.attribute.rights_note', text: 'test rights note'
      expect(page).to have_css '.attribute.viewing_hint', text: 'individuals'
      expect(page).to have_css '.attribute.visibility', text: 'open'
      expect(page).to have_css '.attribute.local_identifier', text: 'test ID'
      expect(page).to have_css '.attribute.portion_note', text: 'test portion note'
      expect(page).to have_css '.attribute.nav_date', text: 'test navigation date'
      expect(page).to have_css '.attribute.member_of_collections', text: 'Title'
    end
  end

  context 'nested within an existing SimpleResource' do
    let(:member) do
      persister.save(resource: FactoryBot.create_for_repository(:simple_resource, title: 'member resource'))
    end
    let(:parent) do
      persister.save(resource: FactoryBot.create_for_repository(:simple_resource, member_ids: [member.id]))
    end
    before do
      parent
    end

    scenario 'saved SimpleResources are displayed as members' do
      visit solr_document_path(parent)

      expect(page).to have_selector 'h2', text: 'Members'
      expect(page).to have_selector 'td', text: 'member resource'
    end
  end
end
