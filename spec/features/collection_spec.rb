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

    # renders rich text editor for description
    element = find("trix-editor > div")
    expect(element.text).to eq collection.description.first

    # Has hidden collection banner image url field
    element = find('#collection_banner_image_url', visible: false)
    expect(element.value).to eq collection.banner_image_url
    # This .openseadragon-container element only gets created when the Vue component successfully renders
    expect(page).to have_css '.openseadragon-container'

    fill_in "Tagline", with: "This is a short tagline."
    # Submit the form
    click_button "Save"
    # Expect the banner_image_url to be the same
    expect(page).to have_css 'td.rendered_banner_image > img[src="https://iiif-cloud.princeton.edu/iiif/2/60%2Fb5%2Fe5%2F60b5e5365600450db52dbe4d7f92b8cc%2Fintermediate_file/642,2316,3854,2569/750,/0/default.jpg"]'
  end

  context "viewing a collection" do
    scenario "when published with a banner image url" do
      collection = FactoryBot.create_for_repository(:collection, publish: true)
      visit solr_document_path(id: collection.id)
      expect(page).to have_text "Banner Image"
      expect(page).to have_css "td.rendered_banner_image > img"
      expect(page).to have_text "Digital Collections URL"
      expect(page).to have_css "td.rendered_dc_url > a[href=\"https://digital-collections.princeton.edu/collections/test\"]"
      expect(page).to have_text "DPUL URL"
      expect(page).to have_css "td.rendered_dpul_url > a[href=\"https://dpul.princeton.edu/test\"]"
      expect(page).to have_text "IIIF Manifest URL"
      expect(page).to have_link href: /collections\/.*\/manifest/\
    end

    scenario "when unpublished and without a banner image url" do
      collection = FactoryBot.create_for_repository(:collection, banner_image_url: nil, publish: false)
      visit solr_document_path(id: collection.id)

      expect(page).not_to have_text "Banner Image"
      expect(page).not_to have_css "td.rendered_banner_image > img"
      expect(page).not_to have_text "Digital Collections URL"
      expect(page).not_to have_css "td.rendered_dc_url > a[href=\"https://digital-collections.princeton.edu/collections/test\"]"
    end

    scenario "with a highlighted item" do
      collection = FactoryBot.create_for_repository(:collection)
      r = FactoryBot.create_for_repository(:scanned_resource, title: "Featured Resource", member_of_collection_ids: [collection.id], featurable: "1")
      ChangeSetPersister.default.save(change_set: ChangeSet.for(r))
      visit solr_document_path(id: collection.id)
      click_link "View Highlighted Items"
      expect(page).to have_text "Featured Resource"
    end
  end
end
