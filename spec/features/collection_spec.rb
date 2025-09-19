# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Collection" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "editing a collection", js: true do
    collection = FactoryBot.create_for_repository(:collection)
    visit edit_collection_path(id: collection.id)

    # edit fields
    expect(page).to have_field "Title", with: collection.title.first
    expect(page).to have_field "DPUL URL", with: collection.slug.first
    expect(page).to have_checked_field "Publish in Digital Collections"
    expect(page).to have_field "Source Metadata ID", with: collection.source_metadata_identifier.first
    expect(page).to have_field "Refresh metadata from PULFA/Catalog"
    expect(page).to have_field "Description", with: collection.description.first
    expect(page).to have_content "Owners"
    expect(page).to have_field "Restricted viewers"
  end
end
