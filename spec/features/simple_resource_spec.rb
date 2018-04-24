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
    stub_ezid(shoulder: '99999/fk4', blade: '123456')

    change_set.sync
    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  scenario 'creating a new resource' do
    visit new_simple_resource_path
    page.save_screenshot('screenshot.png')

    expect(page).to have_field 'Title'
    expect(page).to have_css '.select[for="simple_resource_rights_statement"]', text: 'Rights Statement'
    expect(page).to have_field 'Rights Note'
    expect(page).to have_field 'Local identifier'
    expect(page).to have_css '.select[for="simple_resource_pdf_type"]', text: 'PDF Type'
    expect(page).to have_field 'Portion Note'
    expect(page).to have_field 'Navigation Date'
    expect(page).to have_css '.select[for="simple_resource_member_of_collection_ids"]', text: 'Collections'

    expect(page).to have_field 'Abstract'
    expect(page).to have_field 'Alternative'
    expect(page).to have_field 'Alternative title'
    expect(page).to have_field 'Bibliographic citation'
    expect(page).to have_field 'Contents'
    expect(page).to have_field 'Extent'
    expect(page).to have_field 'Genre'
    expect(page).to have_field 'Geo subject'
    expect(page).to have_field 'License'
    expect(page).to have_field 'Part of'
    expect(page).to have_field 'Replaces'
    expect(page).to have_field 'Type'
    expect(page).to have_field 'Contributor'
    expect(page).to have_css '.control-label[for="simple_resource_coverage"]', text: 'Coverage'
    expect(page).to have_field 'Creator'
    expect(page).to have_field 'Date'
    expect(page).to have_field 'Description'
    expect(page).to have_field 'Keyword'
    expect(page).to have_field 'Language'
    expect(page).to have_field 'Publisher'
    expect(page).to have_field 'Source'
    expect(page).to have_field 'Subject'
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
        nav_date: '01/01/1970',
        member_of_collection_ids: [collection.id],
        abstract: 'test value',
        alternative: 'test value',
        alternative_title: 'test value',
        bibliographic_citation: 'test value',
        contents: 'test value',
        extent: 'test value',
        genre: 'test value',
        geo_subject: 'test value',
        identifier: 'test value',
        license: 'test value',
        part_of: 'test value',
        replaces: 'test value',
        type: 'test value',
        contributor: 'test value',
        coverage: 'test value',
        creator: 'test value',
        date: '01/01/1970',
        description: 'test value',
        keyword: 'test value',
        language: 'test value',
        publisher: 'test value',
        source: 'test value',
        subject: 'test value'
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
      expect(page).to have_css '.attribute.nav_date', text: '01/01/1970'
      expect(page).to have_css '.attribute.member_of_collections', text: 'Title'

      expect(page).to have_css '.attribute.abstract', text: 'test value'
      expect(page).to have_css '.attribute.alternative', text: 'test value'
      expect(page).to have_css '.attribute.alternative_title', text: 'test value'
      expect(page).to have_css '.attribute.bibliographic_citation', text: 'test value'
      expect(page).to have_css '.attribute.contents', text: 'test value'
      expect(page).to have_css '.attribute.extent', text: 'test value'
      expect(page).to have_css '.attribute.genre', text: 'test value'
      expect(page).to have_css '.attribute.geo_subject', text: 'test value'
      expect(page).to have_css '.attribute.identifier', text: 'test value'
      expect(page).to have_css '.attribute.license', text: 'test value'
      expect(page).to have_css '.attribute.part_of', text: 'test value'
      expect(page).to have_css '.attribute.replaces', text: 'test value'
      expect(page).to have_css '.attribute.type', text: 'test value'
      expect(page).to have_css '.attribute.contributor', text: 'test value'
      expect(page).to have_css '.attribute.coverage', text: 'test value'
      expect(page).to have_css '.attribute.creator', text: 'test value'
      expect(page).to have_css '.attribute.date', text: '01/01/1970'
      expect(page).to have_css '.attribute.description', text: 'test value'
      expect(page).to have_css '.attribute.keyword', text: 'test value'
      expect(page).to have_css '.attribute.language', text: 'test value'
      expect(page).to have_css '.attribute.publisher', text: 'test value'
      expect(page).to have_css '.attribute.source', text: 'test value'
      expect(page).to have_css '.attribute.subject', text: 'test value'
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
