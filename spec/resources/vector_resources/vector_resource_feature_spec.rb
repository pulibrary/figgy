# frozen_string_literal: true
require "rails_helper"

RSpec.feature "VectorResources" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  context "when a user creates a new vector resource" do
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:persister) { adapter.persister }
    let(:change_set) do
      VectorResourceChangeSet.new(vector_resource)
    end
    let(:change_set_persister) do
      ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
    end
    let(:vector_resource) do
      FactoryBot.create_for_repository(
        :vector_resource,
        title: "new vector resource",
        visibility: "open",
        identifier: "ark:/99999/fk4",
        creator: "test value",
        description: "test value",
        language: "test value",
        local_identifier: "test ID",
        rights_note: "test rights note",
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        subject: "test value",
        portion_note: "test portion note",
        cartographic_scale: "test value",
        spatial: "test value",
        temporal: "test value",
        issued: "test value"
      )
    end

    before do
      change_set_persister.save(change_set: change_set)
    end

    scenario "viewing a resource" do
      visit solr_document_path vector_resource

      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.title", text: "new vector resource"
      expect(page).to have_css ".attribute.creator", text: "test value"
      expect(page).to have_css ".attribute.description", text: "test value"
      expect(page).to have_css ".attribute.language", text: "test value"
      expect(page).to have_css ".attribute.local_identifier", text: "test ID"
      expect(page).to have_css ".attribute.rights_note", text: "test rights note"
      expect(page).to have_css ".attribute.rights_statement", text: RightsStatements.copyright_not_evaluated.to_s
      expect(page).to have_css ".attribute.subject", text: "test value"
      expect(page).to have_css ".attribute.portion_note", text: "test portion note"
      expect(page).to have_css ".attribute.cartographic_scale", text: "test value"
      expect(page).to have_css ".attribute.held_by", text: "Princeton"
      expect(page).to have_css ".attribute.ark", text: "http://arks.princeton.edu/ark:/99999/fk4"
      expect(page).to have_css "th", text: "Place Name"
      expect(page).to have_css ".attribute.spatial", text: "test value"
      expect(page).to have_css ".attribute.temporal", text: "test value"
      expect(page).to have_css ".attribute.issued", text: "test value"
    end
  end
end
