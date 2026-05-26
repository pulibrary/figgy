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
    expect(page).to have_field "Source Metadata ID"
    expect(page).to have_field "Refresh metadata from PULFA/Catalog"
    expect(page).to have_content "Owners"
    expect(page).to have_field "Restricted viewers"
    expect(page).to have_field "Tagline", with: collection.tagline
    expect(page).to have_button "Load"

    # Has hidden collection banner image url field
    element = find('#collection_banner_image_url', visible: false)
    expect(element.value).to eq collection.banner_image_url

    # renders rich text editor for description
    element = find("trix-editor > div")
    expect(element.text).to eq collection.description.first
  end

  context "with a banner image url" do
    scenario "viewing a collection" do
      collection = FactoryBot.create_for_repository(:collection)
      visit solr_document_path(id: collection.id)
      expect(page).to have_text "Rendered Banner Image"
      expect(page).to have_css "li.rendered_banner_image > img"
    end
  end

  context "without a banner image url" do
    scenario "viewing a collection" do
      collection = FactoryBot.create_for_repository(:collection, banner_image_url: nil)
      visit solr_document_path(id: collection.id)

      expect(page).not_to have_text "Rendered Banner Image"
      expect(page).not_to have_css "li.rendered_banner_image > img"
    end
  end
end
