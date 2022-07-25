# frozen_string_literal: true
require "rails_helper"

RSpec.feature "SimpleChangeSets" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:simple_resource) do
    res = FactoryBot.create_for_repository(:scanned_resource)
    persister.save(resource: res)
  end
  let(:change_set) do
    SimpleChangeSet.new(simple_resource)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")

    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  scenario "visiting a resource show page" do
    visit solr_document_path(simple_resource)

    expect(page).to have_css("title", text: "#{simple_resource.title.first} - Figgy", visible: false)
  end

  scenario "creating a new resource", js: true do
    visit new_simple_scanned_resources_path

    expect(page).to have_field "Title"
    expect(page).to have_css '.select[for="scanned_resource_rights_statement"]', text: "Rights Statement"
    expect(page).to have_field "Rights Note"
    expect(page).to have_field "Local identifier"
    expect(page).to have_css '.select[for="scanned_resource_pdf_type"]', text: "PDF Type"
    expect(page).to have_field "Portion Note"
    expect(page).to have_field "Navigation Date"
    expect(page).to have_css '.select[for="scanned_resource_member_of_collection_ids"]', text: "Collections"

    # The following were disabled until we have support for all these fields.
    # expect(page).to have_field "Abstract"
    # expect(page).to have_field "Alternative"
    # expect(page).to have_field "Alternative title"
    # expect(page).to have_field "Bibliographic citation"
    # expect(page).to have_field "Contents"
    # expect(page).to have_field "Extent"
    # expect(page).to have_field "Genre"
    # expect(page).to have_field "Geo subject"
    # expect(page).to have_field "License"
    # expect(page).to have_field "Part of"
    # expect(page).to have_field "Replaces"
    # expect(page).to have_field "Type"
    # expect(page).to have_field "Contributor"
    # expect(page).to have_css '.control-label[for="scanned_resource_coverage"]', text: "Coverage"
    # expect(page).to have_field "Creator"
    # expect(page).to have_field "Date"
    # expect(page).to have_field "Description"
    # expect(page).to have_field "Keyword"
    # expect(page).to have_field "Language"
    # expect(page).to have_field "Publisher"
    # expect(page).to have_field "Source"
    # expect(page).to have_field "Subject"
    expect(page.find("#scanned_resource_change_set", visible: false).value).to eq "simple"

    click_button "Add another Title"
    expect(page).to have_content "cannot add another"
    fill_in "Title", with: "Test Title"
    click_button "Add another Title"
    input = find_all("*[name='scanned_resource[title][]']").last
    input.fill_in(with: "Second Title")
    click_button "Add another Title"
    input = find_all("*[name='scanned_resource[title][]']").last
    input.fill_in(with: "Third Title")
    find_all("button.btn-link.remove").last.click
    # fill_in "Contributor", with: "Test Contributor"
    click_button "Save"

    expect(page).to have_content "Test Title"
    expect(page).to have_content "Second Title"
    expect(page).not_to have_content "Third Title"
  end

  scenario "creating an invalid resource" do
    visit new_simple_scanned_resources_path
    click_button "Save"

    expect(page).to have_content "You must provide a title"
    expect(page.find("#scanned_resource_change_set", visible: false).value).to eq "simple"
  end

  context "when a user creates a new simple resource" do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:simple_resource) do
      FactoryBot.create_for_repository(
        :simple_resource,
        title: "new simple resource",
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        rights_note: "test rights note",
        local_identifier: "test ID",
        portion_note: "test portion note",
        nav_date: "01/01/1970",
        member_of_collection_ids: [collection.id],
        abstract: "test value",
        alternative: "test value",
        alternative_title: "test value",
        bibliographic_citation: "test value",
        contents: "test value",
        extent: "test value",
        genre: "test value",
        geo_subject: "test value",
        identifier: "test value",
        license: "test value",
        part_of: "test value",
        replaces: "test value",
        type: "test value",
        contributor: "test value",
        coverage: "test value",
        creator: "test value",
        date: "01/01/1970",
        description: "test value",
        keyword: "test value",
        language: "test value",
        publisher: "test value",
        source: "test value",
        subject: "test value"
      )
    end

    scenario "editing a resource" do
      visit edit_scanned_resource_path(simple_resource)

      expect(page).to have_field "Title"
      expect(page).to have_css '.select[for="scanned_resource_rights_statement"]', text: "Rights Statement"
      expect(page).to have_field "Rights Note"
      expect(page).to have_field "Local identifier"
      expect(page).to have_css '.select[for="scanned_resource_pdf_type"]', text: "PDF Type"
      expect(page).to have_field "Portion Note"
      expect(page).to have_field "Navigation Date"
      expect(page).to have_css '.select[for="scanned_resource_member_of_collection_ids"]', text: "Collections"
    end

    scenario "viewing a resource" do
      visit solr_document_path simple_resource

      expect(page).to have_css ".attribute.title", text: "new simple resource"
      expect(page).to have_css ".attribute.rendered_rights_statement", text: "Copyright Not Evaluated"
      expect(page).to have_css ".attribute.rights_note", text: "test rights note"
      expect(page).to have_css ".attribute.viewing_hint", text: "individuals"
      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.local_identifier", text: "test ID"
      expect(page).to have_css ".attribute.portion_note", text: "test portion note"
      expect(page).to have_css ".attribute.nav_date", text: "01/01/1970"
      expect(page).to have_css ".attribute.member_of_collections", text: "Title"

      expect(page).to have_css ".attribute.abstract", text: "test value"
      expect(page).to have_css ".attribute.alternative", text: "test value"
      expect(page).to have_css ".attribute.alternative_title", text: "test value"
      expect(page).to have_css ".attribute.bibliographic_citation", text: "test value"
      expect(page).to have_css ".attribute.contents", text: "test value"
      expect(page).to have_css ".attribute.extent", text: "test value"
      expect(page).to have_css ".attribute.genre", text: "test value"
      expect(page).to have_css ".attribute.geo_subject", text: "test value"
      expect(page).to have_css ".attribute.identifier", text: "test value"
      expect(page).to have_css ".attribute.license", text: "test value"
      expect(page).to have_css ".attribute.part_of", text: "test value"
      expect(page).to have_css ".attribute.replaces", text: "test value"
      expect(page).to have_css ".attribute.type", text: "test value"
      expect(page).to have_css ".attribute.contributor", text: "test value"
      expect(page).to have_css ".attribute.coverage", text: "test value"
      expect(page).to have_css ".attribute.creator", text: "test value"
      expect(page).to have_css ".attribute.date", text: "01/01/1970"
      expect(page).to have_css ".attribute.description", text: "test value"
      expect(page).to have_css ".attribute.keyword", text: "test value"
      expect(page).to have_css ".attribute.language", text: "test value"
      expect(page).to have_css ".attribute.publisher", text: "test value"
      expect(page).to have_css ".attribute.source", text: "test value"
      expect(page).to have_css ".attribute.subject", text: "test value"
    end
  end

  context "nested within an existing SimpleResource" do
    let(:member) do
      persister.save(resource: FactoryBot.create_for_repository(:simple_resource, title: "member resource"))
    end
    let(:parent) do
      persister.save(resource: FactoryBot.create_for_repository(:simple_resource, member_ids: [member.id]))
    end
    before do
      parent
    end

    scenario "saved SimpleResources are displayed as members" do
      visit solr_document_path(parent)

      expect(page).to have_selector "div", text: "Members"
      expect(page).to have_selector "td", text: "member resource"
    end
  end
end
