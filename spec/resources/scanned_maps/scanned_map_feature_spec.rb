# frozen_string_literal: true

require "rails_helper"

RSpec.feature "ScannedMaps" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "creating a new resource" do
    visit new_scanned_map_path

    expect(page).to have_field "Title"
    expect(page).to have_field "Source Metadata ID"
    expect(page).to have_css ".select[for='scanned_map_rights_statement']", text: "Rights Statement"
    expect(page).to have_field "Rights Note"
    expect(page).to have_css ".select[for='scanned_map_pdf_type']", text: "PDF Type"
    expect(page).to have_field "Portion Note"
    expect(page).to have_field "Local identifier"
    expect(page).to have_css ".select[for='scanned_map_holding_location']", text: "Holding Location"
    expect(page).to have_css ".select[for='scanned_map_member_of_collection_ids']", text: "Collections"
    expect(page).to have_css ".control-label[for='scanned_map_coverage']", text: "Coverage"
    expect(page).to have_field "Description"
    expect(page).to have_field "Subject"
    expect(page).to have_field "Place Name"
    expect(page).to have_field "Temporal"
    expect(page).to have_field "Issued"
    expect(page).to have_field "Creator"
    expect(page).to have_field "Language"
    expect(page).to have_field "Cartographic scale"
    expect(page).to have_field "Always show in Pulmap search results"
  end

  context "when a user creates a new scanned map" do
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:persister) { adapter.persister }
    let(:change_set) do
      ScannedMapChangeSet.new(scanned_map)
    end
    let(:change_set_persister) do
      ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
    end
    let(:scanned_map) do
      FactoryBot.create_for_repository(
        :scanned_map,
        title: "new scanned map",
        visibility: "open",
        identifier: "ark:/99999/fk4",
        creator: "test value",
        description: "test value",
        language: "test value",
        local_identifier: "test ID",
        rights_note: "test rights note",
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        subject: "test value",
        pdf_type: "color",
        portion_note: "test portion note",
        cartographic_scale: "test value",
        spatial: "test value",
        temporal: "test value",
        issued: "test value",
        gbl_suppressed_override: true,
        imported_metadata: [{
          extent: "test extent"
        }]
      )
    end

    before do
      change_set_persister.save(change_set: change_set)
    end

    scenario "viewing a resource" do
      visit solr_document_path scanned_map

      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.gbl_suppressed_override", text: "True"
      expect(page).to have_css ".attribute.title", text: "new scanned map"
      expect(page).to have_css ".attribute.creator", text: "test value"
      expect(page).to have_css ".attribute.description", text: "test value"
      expect(page).to have_css ".attribute.language", text: "test value"
      expect(page).to have_css ".attribute.local_identifier", text: "test ID"
      expect(page).to have_css ".attribute.rights_note", text: "test rights note"
      expect(page).to have_css ".attribute.rights_statement", text: RightsStatements.copyright_not_evaluated.to_s
      expect(page).to have_css ".attribute.pdf_type", text: "color"
      expect(page).to have_css ".attribute.subject", text: "test value"
      expect(page).to have_css ".attribute.portion_note", text: "test portion note"
      expect(page).to have_css ".attribute.cartographic_scale", text: "test value"
      expect(page).to have_css ".attribute.held_by", text: "Princeton"
      expect(page).to have_css ".attribute.ark", text: "http://arks.princeton.edu/ark:/99999/fk4"
      expect(page).to have_css "th", text: "Place Name"
      expect(page).to have_css ".attribute.spatial", text: "test value"
      expect(page).to have_css ".attribute.temporal", text: "test value"
      expect(page).to have_css ".attribute.issued", text: "test value"
      expect(page).not_to have_css ".attribute.extent", text: "test extent"
    end
  end
end
